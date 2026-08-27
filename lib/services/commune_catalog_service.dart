import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Une commune de France (≥1500 habitants) avec sa position — pour l'onglet
/// Carte. Pas de prix associé : contrairement aux 96 préfectures de
/// `calculations.dart` (qui ont un repère indicatif codé en dur), le prix
/// d'une commune du catalogue n'est connu qu'après une requête VALORIS à la
/// demande (voir `valoris_service.dart`).
class CommunePoint {
  final String nom;
  final String codeInsee;
  final String codeDepartement;
  final int population;
  final double lat, lon;
  const CommunePoint({
    required this.nom,
    required this.codeInsee,
    required this.codeDepartement,
    required this.population,
    required this.lat,
    required this.lon,
  });

  Map<String, dynamic> toJson() => {'n': nom, 'c': codeInsee, 'd': codeDepartement, 'p': population, 'lat': lat, 'lon': lon};

  factory CommunePoint.fromJson(Map<String, dynamic> j) => CommunePoint(
        nom: j['n'] as String? ?? '',
        codeInsee: j['c'] as String? ?? '',
        codeDepartement: j['d'] as String? ?? '',
        population: (j['p'] as num?)?.toInt() ?? 0,
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lon: (j['lon'] as num?)?.toDouble() ?? 0,
      );
}

const _minPopulation = 1500;
const _cacheKey = 'commune-catalog-v1';
const _cacheDateKey = 'commune-catalog-v1-date';
const _cacheMaxAge = Duration(days: 30);

/// Charge la liste des communes de France (≥1500 habitants) pour l'onglet
/// Carte. L'API officielle geo.api.gouv.fr ne permet pas de filtrer par
/// population côté serveur : un seul gros appel (~35 000 communes, sans
/// filtre) est nécessaire, dont on ne garde que celles ≥1500 habitants —
/// mis en cache localement (30 jours) pour ne pas retélécharger plusieurs
/// Mo à chaque ouverture de l'app.
class CommuneCatalogService {
  List<CommunePoint>? _memory;

  Future<List<CommunePoint>> load() async {
    if (_memory != null) return _memory!;
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString(_cacheDateKey);
    final cachedJson = prefs.getString(_cacheKey);
    if (cachedJson != null && cachedDate != null) {
      final age = DateTime.now().difference(DateTime.tryParse(cachedDate) ?? DateTime(2000));
      if (age < _cacheMaxAge) {
        try {
          final list = (jsonDecode(cachedJson) as List)
              .map((e) => CommunePoint.fromJson(e as Map<String, dynamic>))
              .toList();
          _memory = list;
          return list;
        } catch (_) {
          // cache corrompu : on retélécharge ci-dessous
        }
      }
    }
    return _fetchAndCache(prefs);
  }

  Future<List<CommunePoint>> _fetchAndCache(SharedPreferences prefs) async {
    final uri = Uri.https('geo.api.gouv.fr', '/communes', {
      'fields': 'nom,code,centre,population,departement',
      'format': 'json',
    });
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      final result = <CommunePoint>[];
      for (final raw in data) {
        final j = raw as Map<String, dynamic>;
        final population = (j['population'] as num?)?.toInt() ?? 0;
        if (population < _minPopulation) continue;
        final coords = (j['centre'] as Map<String, dynamic>?)?['coordinates'] as List?;
        if (coords == null || coords.length < 2) continue;
        final departement = j['departement'] as Map<String, dynamic>?;
        result.add(CommunePoint(
          nom: j['nom'] as String? ?? '',
          codeInsee: j['code'] as String? ?? '',
          codeDepartement: departement?['code'] as String? ?? '',
          population: population,
          lat: (coords[1] as num).toDouble(),
          lon: (coords[0] as num).toDouble(),
        ));
      }
      _memory = result;
      unawaited(prefs.setString(_cacheKey, jsonEncode(result.map((c) => c.toJson()).toList())));
      unawaited(prefs.setString(_cacheDateKey, DateTime.now().toIso8601String()));
      return result;
    } catch (_) {
      return [];
    }
  }
}
