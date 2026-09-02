import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

/// Prix médian réel au m² d'une commune, issu des statistiques DVF (voir
/// [PrixReferenceService]) — même rôle que `ValorisPrice`
/// (`valoris_service.dart`), mais alimenté par NOTRE republication plutôt
/// que par un appel direct à l'API VALORIS.
class PrixCommuneRef {
  final double prixMedianM2;
  final int nbVentes;
  const PrixCommuneRef({required this.prixMedianM2, required this.nbVentes});
}

/// Chemin Firebase Storage du fichier — republié par un compte admin depuis
/// l'app (voir `AdminScreen` et `PrixImportService`), exactement comme
/// [loyerCommunesStoragePath] pour les loyers.
const prixCommunesStoragePath = 'reference-data/prix_communes.json';

/// Prix médian réel au m² par commune, issu des statistiques DVF (Demandes
/// de Valeurs Foncières — ventes réellement constatées, données DGFiP,
/// licence ouverte Etalab) publiées sur data.gouv.fr et republiées par un
/// admin depuis l'app (voir `PrixImportService`, `AdminScreen`).
///
/// Remplace l'appel direct à l'API VALORIS (`ValorisService`) comme source
/// PRINCIPALE : contrairement à VALORIS (rafraîchie à son propre rythme,
/// hors de notre contrôle), ce fichier est republiable dès qu'une nouvelle
/// édition DVF sort (deux fois par an, avril/octobre) sans attendre VALORIS.
/// `ValorisService.fetchPrixMedian` consulte ce service en premier et ne
/// retombe sur l'appel réseau VALORIS que pour une commune absente du
/// fichier (ex. avant la toute première publication par un admin).
///
/// Mêmes trois sources et même ordre de priorité que
/// `LoyerReferenceService`, qu'il reproduit à l'identique :
/// 1. Cache local (SharedPreferences, 7 jours).
/// 2. Firebase Storage ([prixCommunesStoragePath]) — la version la plus
///    récente publiée par un admin.
/// 3. Asset embarqué (`assets/data/prix_communes.json`) — vide tant qu'un
///    admin n'a jamais encore publié (voir `AdminScreen`), auquel cas
///    [lookup] renvoie toujours `null` et l'app retombe sur VALORIS en
///    direct, comme avant l'ajout de ce service : aucune régression le
///    temps de la première publication.
class PrixReferenceService {
  static const _cacheKey = 'prix-communes-cache-v1';
  static const _cacheDateKey = 'prix-communes-cache-v1-date';
  static const _cacheMaxAge = Duration(days: 7);

  static Map<String, PrixCommuneRef>? _data;
  static Future<void>? _loading;

  /// À appeler une fois au démarrage (voir `main.dart`), comme
  /// `LoyerReferenceService.preload`.
  static Future<void> preload() {
    return _loading ??= _load();
  }

  /// Force un rechargement immédiat — à appeler juste après qu'un admin a
  /// republié un nouveau fichier (voir `AdminScreen`), pour que la session
  /// en cours reflète la mise à jour tout de suite. Réassigne directement
  /// [_loading] (plutôt que de le mettre à `null` en attendant un futur
  /// appel à [preload]) : sans ça, rien ne redéclenche jamais le
  /// rechargement, et la session continue de lire les anciennes données
  /// (ou, avant toute première publication, retombe sur VALORIS en direct)
  /// jusqu'au prochain redémarrage complet de l'app.
  ///
  /// Efface aussi le cache local (SharedPreferences) avant de relancer
  /// [_load] : sinon, tant que ce cache a moins de 7 jours, [_load] le
  /// relit tel quel sans jamais recontacter Firebase Storage — un
  /// "rechargement forcé" qui, en pratique, ne rechargeait jamais rien de
  /// nouveau dans la même semaine (bug distinct de celui déjà corrigé ici :
  /// celui-là empêchait [_load] d'être seulement rappelé, celui-ci fait
  /// que même rappelé, il ressert la même réponse figée).
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
    try {
      final raw = await rootBundle.loadString('assets/data/prix_communes.json');
      _applyJson(raw);
    } catch (_) {
      _data = {};
    }
  }

  /// Récupère le contenu du fichier en construisant directement l'URL REST
  /// publique de Firebase Storage, plutôt que de passer par
  /// `FirebaseStorage.ref(...).getData()` OU `.getDownloadURL()` — les DEUX
  /// se sont révélés lever le même `TypeError` interne sur Flutter Web
  /// (constaté en conditions réelles, deux correctifs successifs testés
  /// sans effet) : bug d'interop JS partagé par les méthodes de LECTURE du
  /// plugin `firebase_storage` sur le web (l'écriture via `putData`, elle,
  /// fonctionne — chemin de code différent). Ne fonctionne que parce que ce
  /// fichier est public en lecture (voir `storage.rules` :
  /// `allow read: if true`) : pas besoin de jeton d'accès, un simple
  /// `http.get` suffit, sans passer par le SDK Storage du tout pour la
  /// lecture.
  static Future<String> _fetchFromStorage() async {
    final bucket = DefaultFirebaseOptions.currentPlatform.storageBucket;
    final url = Uri.https(
      'firebasestorage.googleapis.com',
      '/v0/b/$bucket/o/${Uri.encodeComponent(prixCommunesStoragePath)}',
      {'alt': 'media'},
    );
    final response = await http.get(url).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      // Le corps de la réponse est décisif pour diagnostiquer une erreur
      // HTTP inattendue ici (ex. 403) : une vraie erreur Firebase a un
      // corps JSON distinctif ("error": {"code", "message"...}), très
      // différent d'une page d'erreur générique injectée par un opérateur
      // mobile ou un bloqueur de contenu — sans ce corps, impossible de
      // distinguer les deux hypothèses depuis l'admin.
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      final bodyPreview = body.length > 300 ? '${body.substring(0, 300)}...' : body;
      throw StateError('HTTP ${response.statusCode} en téléchargeant $prixCommunesStoragePath — corps : $bodyPreview');
    }
    return utf8.decode(response.bodyBytes);
  }

  static void _applyJson(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _data = {
      for (final entry in json.entries)
        entry.key: PrixCommuneRef(
          prixMedianM2: ((entry.value as Map<String, dynamic>)['p'] as num).toDouble(),
          nbVentes: (entry.value['n'] as num).toInt(),
        ),
    };
  }

  /// `null` tant que [preload] n'a pas terminé, ou si la commune n'est pas
  /// (encore) couverte par le fichier republié.
  static PrixCommuneRef? lookup(String codeInsee) {
    if (codeInsee.isEmpty) return null;
    return _data?[codeInsee];
  }

  /// Diagnostic : lecture BRUTE de Firebase Storage, sans passer par le
  /// cache local ni avaler la moindre exception (contrairement à [_load],
  /// qui retombe silencieusement sur un repli en cas d'échec — utile en
  /// production, mais ça masque complètement la vraie cause d'un souci).
  /// À utiliser depuis l'admin quand [lookup] renvoie `null` de façon
  /// persistante malgré un rechargement authentiquement forcé, pour savoir
  /// si le problème vient de la lecture réseau/permissions elle-même
  /// (visible ici) ou d'autre chose.
  static Future<String> diagnosticRawFetch() async {
    try {
      final raw = await _fetchFromStorage();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final poitiers = json['86194'];
      final poitiersTxt = poitiers != null
          ? 'présent (${(poitiers['p'] as num).toStringAsFixed(0)} €/m²)'
          : 'ABSENT';
      return 'Lecture Storage réussie : ${json.length} commune(s), ${raw.length} octets, Poitiers $poitiersTxt.';
    } catch (e) {
      return "Échec de la lecture Storage : ${e.runtimeType} — $e";
    }
  }
}
