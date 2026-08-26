import '../utils/calculations.dart';

/// Un bien enregistré pour comparaison — équivalent d'un élément poussé
/// dans `biens` (`{...form, id, core, regimes, score}`) dans le prototype.
class SavedProperty {
  final int id;
  final PropertyInput form;
  final CoreResult core;
  final List<RegimeResult> regimes;
  final ScoreResult score;

  const SavedProperty({
    required this.id,
    required this.form,
    required this.core,
    required this.regimes,
    required this.score,
  });
}
