import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

/// Un point de la courbe d'évolution du prix — une année pleine.
class PrixHistoriquePoint {
  final int annee;
  final double prixMedianM2;
  final int nbVentes;
  const PrixHistoriquePoint({required this.annee, required this.prixMedianM2, required this.nbVentes});
}

/// Chemin Firebase Storage du fichier — republié par la Cloud Function
/// `refreshRecentPrix` (voir `functions/index.js`), dans le même passage sur
/// le fichier "Statistiques mensuelles DVF" que
/// `reference-data/prix_recents_12mois.json` (voir
/// `PrixRecentReferenceService`) — les deux sont donc toujours republiés
/// ensemble, jamais l'un sans l'autre.
const prixHistoriqueStoragePath = 'reference-data/prix_historique.json';

/// Courbe d'évolution du prix médian réel au m² par commune, un point par
/// année, sur les 5 dernières années PLEINES (l'année en cours est exclue
/// côté Cloud Function tant qu'elle n'est pas terminée — un point sur une
/// année partielle donnerait une impression trompeuse de hausse/baisse liée
/// simplement au nombre de mois couverts, pas au marché réel).
///
/// Rôle complémentaire à [PrixReferenceService] (agrégat fixe sur 5 ans, un
/// seul chiffre) et [PrixRecentReferenceService] (12 derniers mois glissants,
/// un seul chiffre) : celui-ci donne la tendance dans le temps, affichée en
/// courbe — voir son utilisation dans `marche_screen.dart`.
///
/// Mêmes trois sources et même ordre de priorité que
/// [PrixRecentReferenceService], qu'il reproduit à l'identique (y compris le
/// contournement du SDK Storage, voir sa documentation) :
/// 1. Cache local (SharedPreferences, 7 jours).
/// 2. Firebase Storage ([prixHistoriqueStoragePath]).
/// 3. Asset embarqué — inexistant pour ce fichier : [lookup] renvoie
///    simplement `null` tant qu'un admin n'a jamais encore lancé le
///    traitement complet depuis l'écran Administration.
class PrixHistoriqueService {
  static const _cacheKey = 'prix-historique-cache-v1';
  static const _cacheDateKey = 'prix-historique-cache-v1-date';
  static const _cacheMaxAge = Duration(days: 7);

  static Map<String, List<PrixHistoriquePoint>>? _data;
  static Future<void>? _loading;

  /// À appeler une fois au démarrage (voir `main.dart`), comme
  /// `PrixRecentReferenceService.preload`.
  static Future<void> preload() {
    return _loading ??= _load();
  }

  /// Force un rechargement immédiat — même raison d'être que
  /// `PrixRecentReferenceService.invalidateCache`.
  static void invalidateCache() {
    _loading = _forceReload();
  }

  static Future<void> _forceReload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheDateKey);
    } catch (_) {
      // Pas grave : si SharedPreferences est inutilisable, _load() ne
      // trouvera de toute façon pas de cache à relire.
    }
    return _load();
  }

  static Future<void> _load() async {
    String? cachedJson;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDate = prefs.getString(_cacheDateKey);
      cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null && cachedDate != null) {
        final age = DateTime.now().difference(DateTime.tryParse(cachedDate) ?? DateTime(2000));
        if (age < _cacheMaxAge) {
          _applyJson(cachedJson);
          return;
        }
      }
      final raw = await _fetchFromStorage();
      _applyJson(raw);
      unawaited(prefs.setString(_cacheKey, raw));
      unawaited(prefs.setString(_cacheDateKey, DateTime.now().toIso8601String()));
      return;
    } catch (_) {
      // suite ci-dessous
    }
    if (cachedJson != null) {
      try {
        _applyJson(cachedJson);
        return;
      } catch (_) {
        // cache corrompu : dernier repli ci-dessous
      }
    }
    // Pas d'asset embarqué pour ce fichier (voir doc de la classe) : dernier
    // repli direct sur "vide", au lieu de tenter de charger un fichier qui
    // n'existe pas dans le bundle.
    _data = {};
  }

  /// Même contournement du SDK Storage que `PrixRecentReferenceService`,
  /// pour la même raison (bug d'interop JS de `firebase_storage` sur Flutter
  /// Web, voir sa documentation) — construit directement l'URL REST publique.
  static Future<String> _fetchFromStorage() async {
    final bucket = DefaultFirebaseOptions.currentPlatform.storageBucket;
    final url = Uri.parse(
      'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(prixHistoriqueStoragePath)}?alt=media',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      final bodyPreview = body.length > 300 ? '${body.substring(0, 300)}...' : body;
      throw StateError('HTTP ${response.statusCode} en téléchargeant $prixHistoriqueStoragePath — corps : $bodyPreview');
    }
    return utf8.decode(response.bodyBytes);
  }

  static void _applyJson(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _data = {
      for (final entry in json.entries)
        entry.key: [
          for (final point in entry.value as List)
            PrixHistoriquePoint(
              annee: int.parse((point as Map<String, dynamic>)['a'] as String),
              prixMedianM2: (point['p'] as num).toDouble(),
              nbVentes: (point['n'] as num).toInt(),
            ),
        ],
    };
  }

  /// `null` tant que [preload] n'a pas terminé, si la commune n'a pas assez
  /// d'historique exploitable (moins de 2 années pleines avec des ventes),
  /// ou si aucun admin n'a encore lancé le traitement complet depuis l'écran
  /// Administration. Points triés par année croissante.
  static List<PrixHistoriquePoint>? lookup(String codeInsee) {
    if (codeInsee.isEmpty) return null;
    return _data?[codeInsee];
  }
}
