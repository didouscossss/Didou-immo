import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_tab.dart';
import '../models/saved_property.dart';
import '../models/tab_sections.dart';
import '../services/firestore_service.dart';
import '../services/loyer_reference_service.dart';
import '../services/valoris_service.dart';
import '../utils/calculations.dart';
import '../utils/property_input_codec.dart';

enum NiveauMode { novice, avance }

const _biensKey = 'biens-list';
const _onboardingKey = 'onboarding-done';
const _darkModeKey = 'dark-mode';
const _tabOrderKey = 'tab-order';
const _hiddenTabsKey = 'hidden-tabs';
const _bienSectionOrderKey = 'bien-section-order';
const _bienHiddenSectionsKey = 'bien-hidden-sections';

/// État global de l'app — équivalent des `useState`/`useMemo` du composant
/// `RendementApp` du prototype.
///
/// Les biens enregistrés vivent soit en local (`shared_preferences`, mode
/// invité / hors-ligne — équivalent du `window.storage` du prototype),
/// soit sur Firestore une fois un compte lié via [attachAccount] : dans ce
/// second cas ils sont partagés entre appareils et servent de base au
/// comptage des essais gratuits. Le statut d'onboarding, lui, reste
/// toujours local à l'appareil.
class RendementState extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final ValorisService _valoris = ValorisService();

  PropertyInput form = PropertyInput.defaultForm();
  NiveauMode niveau = NiveauMode.novice;
  List<SavedProperty> biens = [];
  bool loaded = false;
  bool showOnboarding = false;
  bool darkMode = false;

  /// Ordre et visibilité des onglets principaux — personnalisables depuis
  /// "Personnaliser mon affichage" (voir `TabCustomizationScreen`),
  /// préférence locale à l'appareil (comme [darkMode]/[niveau], pas
  /// synchronisée entre appareils). [tabOrder] contient TOUJOURS les 7
  /// onglets (jamais un sous-ensemble) : la visibilité passe uniquement par
  /// [hiddenTabs], pour ne jamais perdre la position d'un onglet masqué.
  List<AppTab> tabOrder = List.of(kDefaultTabOrder);
  Set<AppTab> hiddenTabs = {};

  /// Onglets réellement affichés, dans l'ordre personnalisé — ce que lit
  /// `RendementHome` pour construire la barre du bas.
  List<AppTab> get visibleTabOrder => tabOrder.where((t) => !hiddenTabs.contains(t)).toList();

  /// Même principe que [tabOrder]/[hiddenTabs], mais pour les blocs À
  /// L'INTÉRIEUR d'un onglet (voir `kTabSections` et
  /// `SectionCustomizationScreen`) — une entrée par onglet qui possède des
  /// blocs personnalisables ; un onglet absent de [kTabSections] (ex.
  /// "Carte", un seul bloc indissociable) n'a pas cette personnalisation.
  final Map<AppTab, List<String>> _sectionOrders = {};
  final Map<AppTab, Set<String>> _hiddenSections = {};

  List<String> sectionOrder(AppTab tab) => _sectionOrders[tab] ?? List.of(kTabSections[tab]?.defaultOrder ?? const []);
  Set<String> hiddenSections(AppTab tab) => _hiddenSections[tab] ?? const {};

  /// Blocs réellement affichés pour [tab], dans l'ordre personnalisé.
  List<String> visibleSections(AppTab tab) => sectionOrder(tab).where((s) => !hiddenSections(tab).contains(s)).toList();

  /// Prix médian réel (VALORIS/DVF) pour la commune actuellement choisie
  /// dans le formulaire — `null` tant qu'il n'a pas été chargé ou si aucune
  /// donnée n'est disponible pour cette commune (repli sur le repère
  /// indicatif statique, voir `refInfoAjuste`).
  ValorisPrice? liveMarketPrice;
  bool loadingLiveMarketPrice = false;
  String? _lastLiveFetchKey;

  /// Dernière erreur du flux Firestore des biens enregistrés (diagnostic),
  /// non null si `watchProperties` a échoué — sans ça, une erreur du flux
  /// (permissions, index manquant...) restait totalement invisible : la
  /// liste des biens paraissait juste vide, sans aucun message.
  String? cloudError;

  String? _uid;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cloudSub;

  CoreResult get core => computeCore(form);
  List<RegimeResult> get regimes => computeRegimes(form, core);
  List<ProjectionPoint> get projection => buildProjection(
        form,
        core,
        form.dureeProjection,
        form.croissanceLoyer,
        form.croissanceValeur,
      );
  List<AmortissementRow> get amortissement =>
      computeAmortissementSchedule(core.montantEmprunte, form.tauxPct, form.dureePretAns);
  /// Repère indicatif (96 préfectures, voir `nearestReference`), avec le
  /// loyer/m² remplacé par la donnée réelle par commune (jeu "Carte des
  /// loyers", voir `LoyerReferenceService`) dès qu'elle est disponible pour
  /// la commune EXACTE choisie — bien plus précis que le repère des 96
  /// préfectures, qui reste le repli si la commune n'y figure pas ou tant
  /// que `LoyerReferenceService.preload()` (appelé dans `load()`) n'a pas
  /// terminé. Le prix/m², lui, n'est jamais modifié ici : sa version réelle
  /// (VALORIS/DVF) est déjà gérée séparément, voir `liveMarketPrice`.
  RefInfo? get refInfo => _refInfoFor(form.commune);

  /// Fabrique le [RefInfo] d'une commune donnée en fusionnant le repère
  /// statique (`nearestReference`) avec la donnée de loyer réelle par
  /// commune si disponible — utilisé pour le bien en cours de saisie
  /// ([refInfo]) et pour chaque bien déjà enregistré (voir `_decodeSaved`
  /// et `_updateSavedProperty`), pour que le score reste cohérent partout.
  RefInfo? _refInfoFor(CommuneRef? commune) {
    final base = nearestReference(commune);
    if (base == null) return null;
    final live = LoyerReferenceService.lookup(commune?.codeInsee ?? '');
    if (live == null) return base;
    return RefInfo(
      ref: CityRef(base.ref.name, base.ref.prixM2, live.loyerM2, base.ref.tension, base.ref.lat,
          base.ref.lon, base.ref.codeDepartement, base.ref.codeInsee),
      precise: base.precise,
      loyerDonneeCommune: true,
      loyerEstimationZone: live.estimationZone,
    );
  }

  Typology get typology =>
      typologies.firstWhere((t) => t.id == form.typeBien, orElse: () => typologies[2]);
  ReferenceResult? get refs =>
      computeReferences(refInfo, typology, form.surface, mode: form.mode, meuble: form.meuble);

  /// Repère ajusté par typologie — équivalent de `refInfoAjuste` du prototype.
  RefInfo? get refInfoAjuste {
    final ri = refInfo;
    final r = refs;
    if (ri == null || r == null) return ri;
    return RefInfo(
      ref: CityRef(ri.ref.name, r.prixM2, r.loyerM2, ri.ref.tension, ri.ref.lat, ri.ref.lon,
          ri.ref.codeDepartement, ri.ref.codeInsee),
      precise: ri.precise,
      loyerDonneeCommune: ri.loyerDonneeCommune,
      loyerEstimationZone: ri.loyerEstimationZone,
    );
  }

  ScoreResult get score => computeScore(form, core, refInfoAjuste);
  CompareResult get comparaison => compareModes(form);
  TriResult get tri => computeTri(form, core);

  Future<void> load() async {
    // `LoyerReferenceService.preload()` n'est PAS attendu ici : c'est un
    // asset de ~800 Ko (voir sa doc), et bloquer tout le démarrage de l'app
    // dessus serait pire que la légère imprécision temporaire que ça évite
    // (repère statique le temps qu'il finisse de charger, déjà lancé bien
    // plus tôt dans `main.dart`, en parallèle de Firebase). `refInfo`/
    // `refInfoAjuste` sont des getters recalculés à chaque lecture : dès que
    // le chargement termine, le prochain rebuild (n'importe quelle
    // interaction) reflète la donnée réelle sans action particulière.
    try {
      await _loadLocalBiens();
      final prefs = await SharedPreferences.getInstance();
      showOnboarding = !(prefs.getBool(_onboardingKey) ?? false);
      darkMode = prefs.getBool(_darkModeKey) ?? false;
      _loadTabLayout(prefs);
      for (final tab in kTabSections.keys) {
        _loadSectionLayout(prefs, tab);
      }
    } catch (_) {
      showOnboarding = true;
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    darkMode = !darkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, darkMode);
  }

  /// Reconstruit [tabOrder]/[hiddenTabs] depuis les préférences stockées,
  /// en filtrant tout nom qui ne correspondrait plus à un [AppTab] connu
  /// (ex. après un renommage) et en rajoutant à la fin, dans l'ordre par
  /// défaut, les onglets qui manqueraient (ex. après l'ajout d'un nouvel
  /// onglet dans une mise à jour) — sans ça, un onglet nouvellement ajouté
  /// resterait invisible pour un utilisateur ayant déjà personnalisé son
  /// affichage.
  void _loadTabLayout(SharedPreferences prefs) {
    final storedOrder = prefs.getStringList(_tabOrderKey);
    if (storedOrder != null) {
      final known = <AppTab>[];
      for (final name in storedOrder) {
        for (final t in AppTab.values) {
          if (t.name == name && !known.contains(t)) known.add(t);
        }
      }
      for (final t in kDefaultTabOrder) {
        if (!known.contains(t)) known.add(t);
      }
      tabOrder = known;
    }
    final storedHidden = prefs.getStringList(_hiddenTabsKey);
    if (storedHidden != null) {
      hiddenTabs = storedHidden.map((name) => AppTab.values.firstWhere((t) => t.name == name, orElse: () => AppTab.calc)).toSet()
        ..removeWhere((t) => !tabOrder.contains(t));
    }
  }

  /// Nouvel ordre choisi depuis "Personnaliser mon affichage" — [order] doit
  /// contenir exactement les 7 onglets (l'écran ne fait que les réordonner,
  /// jamais en retirer).
  Future<void> setTabOrder(List<AppTab> order) async {
    tabOrder = order;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_tabOrderKey, tabOrder.map((t) => t.name).toList());
  }

  /// Affiche/masque un onglet — refuse de masquer le dernier onglet encore
  /// visible (la barre du bas ne doit jamais se retrouver vide).
  Future<void> setTabHidden(AppTab tab, bool hidden) async {
    if (hidden && hiddenTabs.length >= tabOrder.length - 1 && !hiddenTabs.contains(tab)) return;
    hiddenTabs = {...hiddenTabs};
    if (hidden) {
      hiddenTabs.add(tab);
    } else {
      hiddenTabs.remove(tab);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenTabsKey, hiddenTabs.map((t) => t.name).toList());
  }

  /// Revient à l'ordre et à la visibilité d'origine.
  Future<void> resetTabLayout() async {
    tabOrder = List.of(kDefaultTabOrder);
    hiddenTabs = {};
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tabOrderKey);
    await prefs.remove(_hiddenTabsKey);
  }

  /// Même logique que [_loadTabLayout], pour les blocs à l'intérieur de
  /// [tab] (voir [kTabSections]).
  void _loadSectionLayout(SharedPreferences prefs, AppTab tab) {
    final meta = kTabSections[tab]!;
    var order = List.of(meta.defaultOrder);
    final storedOrder = prefs.getStringList(_sectionOrderKey(tab));
    if (storedOrder != null) {
      final known = <String>[];
      for (final id in storedOrder) {
        if (meta.defaultOrder.contains(id) && !known.contains(id)) known.add(id);
      }
      for (final id in meta.defaultOrder) {
        if (!known.contains(id)) known.add(id);
      }
      order = known;
    }
    _sectionOrders[tab] = order;
    final storedHidden = prefs.getStringList(_hiddenSectionsKey(tab));
    if (storedHidden != null) {
      _hiddenSections[tab] = storedHidden.where((id) => order.contains(id) && id != meta.lockedId).toSet();
    }
  }

  Future<void> setSectionOrder(AppTab tab, List<String> order) async {
    _sectionOrders[tab] = order;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_sectionOrderKey(tab), order);
  }

  /// Masque/affiche un bloc de [tab] — refuse de masquer le bloc verrouillé
  /// de cet onglet ([TabSections.lockedId], s'il y en a un) ou le dernier
  /// bloc encore visible.
  Future<void> setSectionHidden(AppTab tab, String id, bool hidden) async {
    final meta = kTabSections[tab];
    if (meta == null || id == meta.lockedId) return;
    final order = sectionOrder(tab);
    final current = Set<String>.of(hiddenSections(tab));
    if (hidden && current.length >= order.length - 1 && !current.contains(id)) return;
    if (hidden) {
      current.add(id);
    } else {
      current.remove(id);
    }
    _hiddenSections[tab] = current;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenSectionsKey(tab), current.toList());
  }

  Future<void> resetSectionLayout(AppTab tab) async {
    final meta = kTabSections[tab];
    if (meta == null) return;
    _sectionOrders[tab] = List.of(meta.defaultOrder);
    _hiddenSections[tab] = {};
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sectionOrderKey(tab));
    await prefs.remove(_hiddenSectionsKey(tab));
  }

  // L'onglet "Bien" avait cette personnalisation avant les autres (voir
  // historique) : on garde ses clés de préférences d'origine pour ne pas
  // faire perdre silencieusement la mise en page déjà choisie.
  String _sectionOrderKey(AppTab tab) => tab == AppTab.calc ? _bienSectionOrderKey : 'section-order-${tab.name}';
  String _hiddenSectionsKey(AppTab tab) => tab == AppTab.calc ? _bienHiddenSectionsKey : 'hidden-sections-${tab.name}';

  Future<void> _loadLocalBiens() async {
    final prefs = await SharedPreferences.getInstance();
    final biensJson = prefs.getString(_biensKey);
    if (biensJson == null) return;
    final list = jsonDecode(biensJson) as List;
    biens = list.map((raw) => _decodeSaved((raw as Map<String, dynamic>)['id'].toString(),
        raw['form'] as Map<String, dynamic>)).toList();
  }

  SavedProperty _decodeSaved(String id, Map<String, dynamic> formJson) {
    final f = PropertyInputCodec.fromJson(formJson);
    final c = computeCore(f);
    return SavedProperty(
      id: id,
      form: f,
      core: c,
      regimes: computeRegimes(f, c),
      score: computeScore(f, c, _refInfoFor(f.commune)),
    );
  }

  Future<void> _persistLocalBiens() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(biens.map((b) => {'id': b.id, 'form': b.form.toJson()}).toList());
    await prefs.setString(_biensKey, encoded);
  }

  /// À appeler à chaque changement d'état de connexion (voir `AuthGate`).
  /// `uid == null` : mode invité, biens locaux à l'appareil.
  /// `uid != null` : biens synchronisés avec Firestore pour ce compte.
  void attachAccount(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _cloudSub?.cancel();
    _cloudSub = null;
    cloudError = null;
    if (uid == null) {
      _loadLocalBiens().then((_) => notifyListeners());
      return;
    }
    _cloudSub = _firestore.watchProperties(uid).listen((snapshot) {
      // `FirestoreService.saveProperty` écrit les champs du formulaire à
      // plat sur le document (`{...data, 'updatedAt': ...}`), contrairement
      // à la sauvegarde locale qui les imbrique sous `form` — `doc.data()`
      // est donc directement le bon shape ici, sans clé `form` à extraire.
      try {
        biens = snapshot.docs.map((doc) => _decodeSaved(doc.id, doc.data())).toList();
        cloudError = null;
      } catch (e) {
        cloudError = e.toString();
      }
      notifyListeners();
    }, onError: (Object e) {
      cloudError = e.toString();
      notifyListeners();
    });
  }

  void updateForm(PropertyInput Function(PropertyInput current) updater) {
    form = updater(form);
    notifyListeners();
    _maybeRefreshLiveMarketPrice();
  }

  /// Récupère le prix médian réel (VALORIS/DVF) pour la commune du
  /// formulaire, uniquement quand elle change (jamais en boucle) — l'API
  /// est limitée à 100 requêtes/jour par IP, donc on ne l'interroge que
  /// pour LA commune que l'utilisateur regarde vraiment, pas en masse.
  void _maybeRefreshLiveMarketPrice() {
    final c = form.commune;
    if (c == null || c.codeDepartement.isEmpty) {
      if (_lastLiveFetchKey != null) {
        _lastLiveFetchKey = null;
        liveMarketPrice = null;
        loadingLiveMarketPrice = false;
        notifyListeners();
      }
      return;
    }
    final key = '${c.codeDepartement}:${c.codeInsee}';
    if (key == _lastLiveFetchKey) return;
    _lastLiveFetchKey = key;
    liveMarketPrice = null;
    loadingLiveMarketPrice = true;
    notifyListeners();
    _valoris.fetchPrixMedian(codeDepartement: c.codeDepartement, codeInsee: c.codeInsee).then((price) {
      if (_lastLiveFetchKey != key) return; // la commune a re-changé entre-temps
      liveMarketPrice = price;
      loadingLiveMarketPrice = false;
      notifyListeners();
    });
  }

  void setNiveau(NiveauMode n) {
    niveau = n;
    notifyListeners();
  }

  /// Bien actuellement en cours de modification (voir [loadPropertyForEditing]) —
  /// `null` signifie que le prochain enregistrement crée un nouveau bien.
  String? editingId;

  /// Recharge un bien déjà enregistré dans le formulaire pour le modifier.
  /// Le prochain [saveCurrentProperty] mettra à jour ce bien au lieu d'en
  /// créer un nouveau.
  void loadPropertyForEditing(SavedProperty b) {
    form = b.form;
    editingId = b.id;
    notifyListeners();
  }

  /// Enregistre le bien courant pour comparaison — équivalent de `handleSave`.
  /// Met à jour le bien en cours d'édition ([editingId]) s'il y en a un, sinon
  /// en crée un nouveau. L'appelant (voir `RendementHome`) est responsable
  /// d'avoir déjà vérifié la capacité d'enregistrement gratuite / l'abonnement
  /// au préalable, et doit attendre ce Future pour savoir si l'enregistrement
  /// a réussi avant de changer d'écran.
  Future<void> saveCurrentProperty() async {
    final id = editingId ?? DateTime.now().millisecondsSinceEpoch.toString();
    if (_uid != null) {
      await _firestore.saveProperty(_uid!, id, form.toJson());
      editingId = null;
      return; // le flux Firestore mettra `biens` à jour automatiquement.
    }
    final saved = SavedProperty(id: id, form: form, core: core, regimes: regimes, score: score);
    final idx = biens.indexWhere((b) => b.id == id);
    biens = idx == -1 ? [...biens, saved] : [for (final b in biens) if (b.id == id) saved else b];
    editingId = null;
    notifyListeners();
    await _persistLocalBiens();
  }

  /// Marque un bien enregistré comme acheté (ou revient en arrière) —
  /// indépendant du formulaire en cours d'édition, met à jour directement
  /// le bien correspondant dans [biens].
  Future<void> setPropertyAchete(String id, bool achete, {DateTime? dateAchat}) =>
      _updateSavedProperty(id, (f) => f.copyWith(achete: achete, dateAchat: dateAchat));

  /// Marque un bien acquis comme vendu (ou annule une vente enregistrée par
  /// erreur) — un bien vendu sort du patrimoine actuellement détenu mais
  /// garde son historique d'achat/revente (voir l'onglet Comparer).
  Future<void> setPropertyVendu(String id, bool vendu, {DateTime? dateVente, double? prixVente}) =>
      _updateSavedProperty(id, (f) => f.copyWith(vendu: vendu, dateVente: dateVente, prixVente: prixVente));

  /// Ajoute un relevé réel (onglet Patrimoine) sur un bien acquis — trié par
  /// date de début à l'insertion pour que le graphique/l'historique restent
  /// dans l'ordre sans devoir re-trier à chaque lecture.
  Future<void> addSuiviEntry(String id, SuiviEntry entry) => _updateSavedProperty(
      id, (f) => f.copyWith(suivi: [...f.suivi, entry]..sort((a, b) => a.dateDebut.compareTo(b.dateDebut))));

  /// Remplace un relevé existant (édition) — identifié par référence
  /// d'objet, comme [deleteSuiviEntry].
  Future<void> updateSuiviEntry(String id, SuiviEntry ancien, SuiviEntry nouveau) => _updateSavedProperty(
      id,
      (f) => f.copyWith(
          suivi: [for (final s in f.suivi) if (s == ancien) nouveau else s]
            ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut))));

  Future<void> deleteSuiviEntry(String id, SuiviEntry entry) =>
      _updateSavedProperty(id, (f) => f.copyWith(suivi: f.suivi.where((s) => s != entry).toList()));

  /// Marque un bien acquis comme résidence principale (ou revient en
  /// arrière) — exclu du cash-flow réel du portefeuille et de la
  /// distinction actif/passif dans l'onglet Patrimoine, voir
  /// `PropertyInput.residencePrincipale`.
  Future<void> setResidencePrincipale(String id, bool value) =>
      _updateSavedProperty(id, (f) => f.copyWith(residencePrincipale: value));

  Future<void> _updateSavedProperty(String id, PropertyInput Function(PropertyInput f) updater) async {
    final idx = biens.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    final newForm = updater(biens[idx].form);
    if (_uid != null) {
      await _firestore.saveProperty(_uid!, id, newForm.toJson());
      return; // le flux Firestore mettra `biens` à jour automatiquement.
    }
    final updated = SavedProperty(
      id: id,
      form: newForm,
      core: computeCore(newForm),
      regimes: computeRegimes(newForm, computeCore(newForm)),
      score: computeScore(newForm, computeCore(newForm), _refInfoFor(newForm.commune)),
    );
    biens = [for (final b in biens) if (b.id == id) updated else b];
    notifyListeners();
    await _persistLocalBiens();
  }

  void deleteProperty(String id) {
    if (_uid != null) {
      _firestore.deleteProperty(_uid!, id);
      return;
    }
    biens = biens.where((b) => b.id != id).toList();
    notifyListeners();
    _persistLocalBiens();
  }

  /// Équivalent de `finishOnboarding`.
  Future<void> finishOnboarding({RentalMode? mode, double? budget}) async {
    if (budget != null && mode != null) {
      form = form.copyWith(
        mode: mode,
        prix: budget,
        notaire: defaultNotaire(budget),
        travaux: defaultTravaux(form.surface),
      );
    }
    showOnboarding = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  @override
  void dispose() {
    _cloudSub?.cancel();
    super.dispose();
  }
}
