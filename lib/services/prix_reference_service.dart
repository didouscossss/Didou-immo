import 'dart:async';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

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
      final bytes = await FirebaseStorage.instance.ref(prixCommunesStoragePath).getData(10 << 20);
      if (bytes == null) throw StateError('empty');
      final raw = utf8.decode(bytes);
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
}
