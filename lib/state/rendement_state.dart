import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_property.dart';
import '../services/firestore_service.dart';
import '../utils/calculations.dart';
import '../utils/property_input_codec.dart';

enum NiveauMode { novice, avance }

const _biensKey = 'biens-list';
const _onboardingKey = 'onboarding-done';

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

  PropertyInput form = PropertyInput.defaultForm();
  NiveauMode niveau = NiveauMode.novice;
  List<SavedProperty> biens = [];
  bool loaded = false;
  bool showOnboarding = false;

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
  RefInfo? get refInfo => nearestReference(form.commune);
  Typology get typology =>
      typologies.firstWhere((t) => t.id == form.typeBien, orElse: () => typologies[2]);
  ReferenceResult? get refs => computeReferences(refInfo, typology, form.surface);

  /// Repère ajusté par typologie — équivalent de `refInfoAjuste` du prototype.
  RefInfo? get refInfoAjuste {
    final ri = refInfo;
    final r = refs;
    if (ri == null || r == null) return ri;
    return RefInfo(
      ref: CityRef(ri.ref.name, r.prixM2, r.loyerM2, ri.ref.tension),
      precise: ri.precise,
    );
  }

  ScoreResult get score => computeScore(form, core, refInfoAjuste);
  CompareResult get comparaison => compareModes(form);

  Future<void> load() async {
    try {
      await _loadLocalBiens();
      final prefs = await SharedPreferences.getInstance();
      showOnboarding = !(prefs.getBool(_onboardingKey) ?? false);
    } catch (_) {
      showOnboarding = true;
    }
    loaded = true;
    notifyListeners();
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
    if (uid == null) {
      _loadLocalBiens().then((_) => notifyListeners());
      return;
    }
    _cloudSub = _firestore.watchProperties(uid).listen((snapshot) {
      biens = snapshot.docs
          .map((doc) => _decodeSaved(doc.id, doc.data()['form'] as Map<String, dynamic>))
          .toList();
      notifyListeners();
    });
  }

  void updateForm(PropertyInput Function(PropertyInput current) updater) {
    form = updater(form);
    notifyListeners();
  }

  void setNiveau(NiveauMode n) {
    niveau = n;
    notifyListeners();
  }

  /// Enregistre le bien courant pour comparaison — équivalent de `handleSave`.
  /// L'appelant (voir `RendementHome`) est responsable d'avoir déjà vérifié
  /// la capacité d'enregistrement gratuite / l'abonnement au préalable, et
  /// doit attendre ce Future pour savoir si l'enregistrement a réussi avant
  /// de changer d'écran.
  Future<void> saveCurrentProperty() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    if (_uid != null) {
      await _firestore.saveProperty(_uid!, id, form.toJson());
      return; // le flux Firestore mettra `biens` à jour automatiquement.
    }
    final saved = SavedProperty(id: id, form: form, core: core, regimes: regimes, score: score);
    biens = [...biens, saved];
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
        notaire: (budget * 0.08).roundToDouble(),
        travaux: (budget * 0.03).roundToDouble(),
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
