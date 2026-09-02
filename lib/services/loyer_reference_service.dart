import 'dart:async';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

/// Chemin Firebase Storage du fichier — republié par un compte admin depuis
/// l'app (voir `AdminScreen` et `LoyerImportService`), pas par une nouvelle
/// version d'app : la donnée est trop volumineuse et évolue trop souvent
/// (une nouvelle édition par an) pour justifier de repasser par une
/// publication Play Store à chaque fois.
const loyerCommunesStoragePath = 'reference-data/loyers_communes.json';

/// Loyer/m² par commune — jeu de données "Carte des loyers" (Ministère
/// chargé du Logement / ANIL, modélisé à partir des annonces LeBonCoin et
/// SeLoger), bien plus fin que le repère des 96 préfectures de
/// `frenchCities` (`calculations.dart`), qui reste le repli pour les
/// DOM-TOM et les rares communes absentes du jeu de données.
///
/// Trois sources possibles, dans l'ordre :
/// 1. Cache local (SharedPreferences, 7 jours) — évite de retélécharger le
///    fichier (~800 Ko) à chaque démarrage.
/// 2. Firebase Storage ([loyerCommunesStoragePath]) — la version la plus
///    récente publiée par un admin.
/// 3. Asset embarqué dans l'app (`assets/data/loyers_communes.json`) —
///    figé à la date du build, dernier repli si le réseau/Storage sont
///    indisponibles (ou si un cache périmé mais utilisable existe, celui-ci
///    est préféré à l'asset embarqué : plus récent).
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
  static const _cacheKey = 'loyers-communes-cache-v1';
  static const _cacheDateKey = 'loyers-communes-cache-v1-date';
  static const _cacheMaxAge = Duration(days: 7);

  static Map<String, LoyerCommuneRef>? _data;
  static Future<void>? _loading;

  /// À appeler une fois au démarrage (voir `main.dart`) — les lectures
  /// suivantes via [lookup] sont synchrones et ne redéclenchent jamais de
  /// chargement.
  static Future<void> preload() {
    return _loading ??= _load();
  }

  /// Force un rechargement immédiat — à appeler juste après qu'un admin a
  /// republié un nouveau fichier (voir `AdminScreen`), pour que la session
  /// en cours reflète la mise à jour sans attendre 7 jours ou un
  /// redémarrage de l'app. Réassigne directement [_loading] (plutôt que de
  /// le mettre à `null` en attendant un futur appel à [preload]) : sans ça,
  /// rien ne redéclenche jamais le rechargement dans la session en cours.
  ///
  /// Efface aussi le cache local (SharedPreferences) avant de relancer
  /// [_load] : sinon, tant que ce cache a moins de 7 jours, [_load] le
  /// relit tel quel sans jamais recontacter Firebase Storage — un
  /// "rechargement forcé" qui, en pratique, ne rechargeait jamais rien de
  /// nouveau dans la même semaine (voir `PrixReferenceService.invalidateCache`
  /// pour le même correctif, appliqué là après un bug constaté en
  /// conditions réelles).
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
      // Cache absent ou périmé : tente Firebase Storage, la source la plus
      // à jour. Toute erreur (Firebase non configuré, pas de réseau, fichier
      // pas encore publié...) retombe silencieusement plus bas, jamais
      // d'erreur visible pour l'utilisateur.
      final raw = await _fetchFromStorage();
      _applyJson(raw);
      unawaited(prefs.setString(_cacheKey, raw));
      unawaited(prefs.setString(_cacheDateKey, DateTime.now().toIso8601String()));
      return;
    } catch (_) {
      // suite ci-dessous
    }
    if (cachedJson != null) {
      // Périmé (>7 jours) mais toujours mieux qu'un asset figé au build.
      try {
        _applyJson(cachedJson);
        return;
      } catch (_) {
        // cache corrompu : dernier repli ci-dessous
      }
    }
    try {
      final raw = await rootBundle.loadString('assets/data/loyers_communes.json');
      _applyJson(raw);
    } catch (_) {
      _data = {};
    }
  }

  /// Récupère le contenu du fichier via [FirebaseStorage.ref.getDownloadURL]
  /// suivi d'un `http.get` classique, plutôt que
  /// `FirebaseStorage.ref.getData` directement : ce dernier repose sur une
  /// interop JS fragile sur Flutter Web, qui peut lever un `TypeError`
  /// interne sans rapport avec le contenu du fichier ou les permissions
  /// (bug connu du plugin, voir flutterfire#12367 — même correctif que
  /// `PrixReferenceService`, où le souci a été constaté en conditions
  /// réelles). `getDownloadURL` + une requête HTTP classique contourne
  /// complètement ce chemin défaillant.
  static Future<String> _fetchFromStorage() async {
    final url = await FirebaseStorage.instance.ref(loyerCommunesStoragePath).getDownloadURL();
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw StateError('HTTP ${response.statusCode} en téléchargeant $loyerCommunesStoragePath');
    }
    return utf8.decode(response.bodyBytes);
  }

  static void _applyJson(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _data = {
      for (final entry in json.entries)
        entry.key: LoyerCommuneRef(
          loyerM2: ((entry.value as Map<String, dynamic>)['m'] as num).toDouble(),
          estimationZone: entry.value['z'] == 1,
        ),
    };
  }

  /// `null` tant que [preload] n'a pas terminé, ou si la commune n'est pas
  /// dans le jeu de données.
  static LoyerCommuneRef? lookup(String codeInsee) {
    if (codeInsee.isEmpty) return null;
    return _data?[codeInsee];
  }
}
