import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_property.dart';
import '../services/firestore_service.dart';
import '../services/valoris_service.dart';
import '../utils/calculations.dart';
import '../utils/property_input_codec.dart';

enum NiveauMode { novice, avance }

const _biensKey = 'biens-list';
const _onboardingKey = 'onboarding-done';
const _darkModeKey = 'dark-mode';

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
  RefInfo? get refInfo => nearestReference(form.commune);
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
    );
  }

  ScoreResult get score => computeScore(form, core, refInfoAjuste);
  CompareResult get comparaison => compareModes(form);
  TriResult get tri => computeTri(form, core);

  Future<void> load() async {
    try {
      await _loadLocalBiens();
      final prefs = await SharedPreferences.getInstance();
      showOnboarding = !(prefs.getBool(_onboardingKey) ?? false);
      darkMode = prefs.getBool(_darkModeKey) ?? false;
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
      score: computeScore(f, c, nearestReference(f.commune)),
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
      score: computeScore(newForm, computeCore(newForm), nearestReference(newForm.commune)),
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
