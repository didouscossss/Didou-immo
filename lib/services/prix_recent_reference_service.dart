import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

/// Prix médian réel au m² d'une commune sur les 12 derniers mois glissants
/// (voir [PrixRecentReferenceService]) — complète [PrixCommuneRef]
/// (`prix_reference_service.dart`), qui reste sur un agrégat fixe de 5 ans.
class PrixRecentCommuneRef {
  final double prixMedianM2;
  final int nbVentes;
  const PrixRecentCommuneRef({required this.prixMedianM2, required this.nbVentes});
}

/// Chemin Firebase Storage du fichier — republié par la Cloud Function
/// `refreshRecentPrix` (voir `functions/index.js`), déclenchée depuis
/// l'écran Administration. Contrairement à [prixCommunesStoragePath],
/// jamais republié directement depuis l'app : le fichier source
/// ("Statistiques mensuelles DVF", ~264 Mo) est bien trop lourd pour être
/// téléchargé et traité depuis un téléphone.
const prixRecentsStoragePath = 'reference-data/prix_recents_12mois.json';

/// Prix médian réel au m² par commune sur les 12 derniers mois glissants,
/// calculé côté serveur (Cloud Function `refreshRecentPrix`) à partir du
/// fichier "Statistiques mensuelles DVF" de data.gouv.fr — chaque ligne du
/// fichier source n'étant qu'UN SEUL mois, la fonction combine les médianes
/// mensuelles des 12 derniers mois disponibles, pondérées par le nombre de
/// ventes de chaque mois (approximation raisonnable en l'absence des
/// transactions individuelles, voir `functions/index.js`).
///
/// Rôle complémentaire à [PrixReferenceService] : celui-ci reste la source
/// principale (agrégat DVF officiel sur 5 ans, plus de recul), ce
/// service-ci donne un repère plus récent quand il est disponible — voir
/// son utilisation dans `carte_screen.dart`.
///
/// Mêmes trois sources et même ordre de priorité que [PrixReferenceService],
/// qu'il reproduit à l'identique (y compris le contournement du SDK
/// Storage, voir sa documentation) :
/// 1. Cache local (SharedPreferences, 7 jours).
/// 2. Firebase Storage ([prixRecentsStoragePath]).
/// 3. Asset embarqué — inexistant pour ce fichier (jamais figé au build,
///    contrairement au fichier "5 ans") : [lookup] renvoie simplement
///    `null` tant qu'un admin n'a jamais encore lancé le traitement complet
///    depuis l'écran Administration, sans erreur ni régression.
class PrixRecentReferenceService {
  static const _cacheKey = 'prix-recents-12mois-cache-v1';
  static const _cacheDateKey = 'prix-recents-12mois-cache-v1-date';
  static const _cacheMaxAge = Duration(days: 7);

  static Map<String, PrixRecentCommuneRef>? _data;
  static Future<void>? _loading;

  /// À appeler une fois au démarrage (voir `main.dart`), comme
  /// `PrixReferenceService.preload`.
  static Future<void> preload() {
    return _loading ??= _load();
  }

  /// Force un rechargement immédiat — même raison d'être que
  /// `PrixReferenceService.invalidateCache`.
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

  /// Même contournement du SDK Storage que `PrixReferenceService`, pour la
  /// même raison (bug d'interop JS de `firebase_storage` sur Flutter Web,
  /// voir sa documentation) — construit directement l'URL REST publique.
  static Future<String> _fetchFromStorage() async {
    final bucket = DefaultFirebaseOptions.currentPlatform.storageBucket;
    final url = Uri.parse(
      'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(prixRecentsStoragePath)}?alt=media',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      final bodyPreview = body.length > 300 ? '${body.substring(0, 300)}...' : body;
      throw StateError('HTTP ${response.statusCode} en téléchargeant $prixRecentsStoragePath — corps : $bodyPreview');
    }
    return utf8.decode(response.bodyBytes);
  }

  static void _applyJson(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _data = {
      for (final entry in json.entries)
        entry.key: PrixRecentCommuneRef(
          prixMedianM2: ((entry.value as Map<String, dynamic>)['p'] as num).toDouble(),
          nbVentes: (entry.value['n'] as num).toInt(),
        ),
    };
  }

  /// `null` tant que [preload] n'a pas terminé, si la commune n'a pas assez
  /// de ventes sur les 12 derniers mois pour être incluse, ou si aucun admin
  /// n'a encore lancé le traitement complet depuis l'écran Administration.
  static PrixRecentCommuneRef? lookup(String codeInsee) {
    if (codeInsee.isEmpty) return null;
    return _data?[codeInsee];
  }
}
