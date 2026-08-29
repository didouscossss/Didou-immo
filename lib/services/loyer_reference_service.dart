import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Loyer/m² d'une commune, issu du jeu "Carte des loyers" (voir
/// [LoyerReferenceService]).
class LoyerCommuneRef {
  final double loyerM2;
  /// true si la commune elle-même n'a pas assez d'annonces observées pour
  /// une estimation propre : la valeur vient alors d'une zone statistique
  /// plus large qui l'englobe ("maille"), pas directement de la commune.
  final bool estimationZone;
  const LoyerCommuneRef({required this.loyerM2, required this.estimationZone});
}

/// Loyer/m² par commune — jeu de données "Carte des loyers" (Ministère
/// chargé du Logement / ANIL, édition 2025, modélisé à partir des annonces
/// LeBonCoin et SeLoger du 3ᵉ trimestre 2025), embarqué dans l'app en asset
/// JSON compact (`assets/data/loyers_communes.json`, ~34 900 communes de
/// France métropolitaine) — voir le script de génération dans l'historique
/// de la PR qui l'a ajouté.
///
/// Contrairement à VALORIS (prix, appel réseau à la demande, quota
/// 100 requêtes/jour), c'est un asset embarqué : pas de réseau, pas de
/// quota, disponible pour absolument toutes les communes du jeu de données
/// dès que [preload] a terminé — bien plus fin que le repère des 96
/// préfectures de `frenchCities` (`calculations.dart`), qui reste le repli
/// pour les DOM-TOM et les rares communes absentes du jeu de données.
///
/// ⚠️ Ce sont des LOYERS D'ANNONCE modélisés (prix demandé, pas forcément
/// obtenu), pas des baux réellement signés comme DVF l'est pour les ventes
/// — à traiter comme un repère, pas une vérité absolue (voir [estimationZone]
/// pour distinguer une estimation directe d'une estimation de zone élargie).
/// Attribution requise par la licence : « Estimations ANIL, d'après des
/// données du groupe SeLoger et de leboncoin » (voir marche_screen.dart).
///
/// ⚠️ Paris, Lyon et Marseille sont absents sous leur code INSEE "ville"
/// (75056/69123/13055, celui que `CommuneRef.codeInsee` porte quand ces
/// villes sont choisies) : le jeu de données ne connaît que leurs
/// arrondissements (75101-75120, etc.), pas de code agrégé pour la ville
/// entière. [lookup] renvoie donc `null` pour ces trois villes précises et
/// l'app retombe sur le repère statique de `frenchCities` — déjà correct
/// pour elles, sans quoi il faudrait choisir un arrondissement précis pour
/// que la moyenne ait un sens (les loyers y varient énormément d'un
/// arrondissement à l'autre).
class LoyerReferenceService {
  static Map<String, LoyerCommuneRef>? _data;
  static Future<void>? _loading;

  /// À appeler une fois au démarrage (voir `RendementState.load`) — les
  /// lectures suivantes via [lookup] sont synchrones et ne redéclenchent
  /// jamais de chargement.
  static Future<void> preload() {
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/loyers_communes.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _data = {
        for (final entry in json.entries)
          entry.key: LoyerCommuneRef(
            loyerM2: ((entry.value as Map<String, dynamic>)['m'] as num).toDouble(),
            estimationZone: entry.value['z'] == 1,
          ),
      };
    } catch (_) {
      // Asset manquant/corrompu : l'app retombe sur le repère statique de
      // `frenchCities`, jamais d'erreur visible pour l'utilisateur.
      _data = {};
    }
  }

  /// `null` tant que [preload] n'a pas terminé, ou si la commune n'est pas
  /// dans le jeu de données.
  static LoyerCommuneRef? lookup(String codeInsee) {
    if (codeInsee.isEmpty) return null;
    return _data?[codeInsee];
  }
}
