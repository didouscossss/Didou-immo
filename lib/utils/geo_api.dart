import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Recherche de communes (jusqu'au plus petit village) via l'API officielle
/// et gratuite geo.api.gouv.fr (IGN/INSEE). Sans clé, sans limite : c'est un
/// service public, pas une API facturée. Aucune base de communes codée en dur.
class CommuneResult {
  final String nom;
  final String code;
  final List<String> codesPostaux;
  final int population;
  final String? departementNom;
  final String? departementCode;

  const CommuneResult({
    required this.nom,
    required this.code,
    required this.codesPostaux,
    required this.population,
    this.departementNom,
    this.departementCode,
  });

  factory CommuneResult.fromJson(Map<String, dynamic> json) {
    final departement = json['departement'] as Map<String, dynamic>?;
    return CommuneResult(
      nom: json['nom'] as String? ?? '',
      code: json['code'] as String? ?? '',
      codesPostaux: (json['codesPostaux'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      population: (json['population'] as num?)?.toInt() ?? 0,
      departementNom: departement?['nom'] as String?,
      departementCode: departement?['code'] as String?,
    );
  }
}

class CommuneSearchOutcome {
  final bool ok;
  final List<CommuneResult> results;
  const CommuneSearchOutcome({required this.ok, required this.results});
}

Future<CommuneSearchOutcome> searchCommunes(String query) async {
  if (query.trim().length < 2) return const CommuneSearchOutcome(ok: true, results: []);
  final uri = Uri.https('geo.api.gouv.fr', '/communes', {
    'nom': query.trim(),
    'fields': 'nom,code,codesPostaux,population,departement',
    'boost': 'population',
    'limit': '8',
  });
  try {
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw Exception('http ${res.statusCode}');
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return CommuneSearchOutcome(
      ok: true,
      results: data.map((e) => CommuneResult.fromJson(e as Map<String, dynamic>)).toList(),
    );
  } catch (_) {
    return const CommuneSearchOutcome(ok: false, results: []);
  }
}
