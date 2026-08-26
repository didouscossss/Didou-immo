import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_property.dart';
import '../utils/calculations.dart';
import '../utils/property_input_codec.dart';

enum NiveauMode { novice, avance }

const _biensKey = 'biens-list';
const _onboardingKey = 'onboarding-done';

/// État global de l'app — équivalent des `useState`/`useMemo` du composant
/// `RendementApp` du prototype. Les biens enregistrés et le statut
/// d'onboarding sont persistés localement (équivalent du `window.storage`
/// du prototype).
class RendementState extends ChangeNotifier {
  PropertyInput form = PropertyInput.defaultForm();
  NiveauMode niveau = NiveauMode.novice;
  List<SavedProperty> biens = [];
  bool loaded = false;
  bool showOnboarding = false;

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
      final prefs = await SharedPreferences.getInstance();
      final biensJson = prefs.getString(_biensKey);
      if (biensJson != null) {
        final list = jsonDecode(biensJson) as List;
        biens = list.map((raw) {
          final map = raw as Map<String, dynamic>;
          final f = PropertyInputCodec.fromJson(map['form'] as Map<String, dynamic>);
          final c = computeCore(f);
          return SavedProperty(
            id: (map['id'] as num).toInt(),
            form: f,
            core: c,
            regimes: computeRegimes(f, c),
            score: computeScore(f, c, nearestReference(f.commune)),
          );
        }).toList();
      }
      showOnboarding = !(prefs.getBool(_onboardingKey) ?? false);
    } catch (_) {
      showOnboarding = true;
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _persistBiens() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(biens
        .map((b) => {'id': b.id, 'form': b.form.toJson()})
        .toList());
    await prefs.setString(_biensKey, encoded);
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
  void saveCurrentProperty() {
    final saved = SavedProperty(
      id: DateTime.now().millisecondsSinceEpoch,
      form: form,
      core: core,
      regimes: regimes,
      score: score,
    );
    biens = [...biens, saved];
    notifyListeners();
    _persistBiens();
  }

  void deleteProperty(int id) {
    biens = biens.where((b) => b.id != id).toList();
    notifyListeners();
    _persistBiens();
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
}
