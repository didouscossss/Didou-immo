import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'prix_reference_service.dart';

/// Prix médian réel au m², issu des transactions notariales (DVF). Deux
/// sources, dans l'ordre :
/// 1. [PrixReferenceService] — notre republication des statistiques DVF
///    officielles (voir `PrixImportService`, `AdminScreen`), rafraîchissable
///    par un admin dès qu'une nouvelle édition sort, sans dépendre du
///    rythme de mise à jour d'un tiers.
/// 2. L'API publique et gratuite VALORIS (valoris-immo.fr) en repli, pour
///    une commune pas encore couverte par notre fichier (ex. avant sa
///    toute première publication) — licence ouverte Etalab. Utilisation
///    soumise à attribution obligatoire : mentionner
///    « VALORIS / DVF — Licence Ouverte » partout où cette donnée est
///    affichée (voir `carte_screen.dart` et `marche_screen.dart`).
class ValorisPrice {
  final double prixMedianM2;
  final int nbTransactions;
  final double? evolution1AnPct;
  /// `null` quand la donnée vient de notre fichier republié : celui-ci
  /// agrège les ventes sur plusieurs années en une seule ligne par commune
  /// (voir `PrixImportService`), sans année de référence précise ni
  /// évolution sur 1 an calculable — contrairement à l'API VALORIS en
  /// direct, qui fournit les deux.
  final int? annee;
  const ValorisPrice({
    required this.prixMedianM2,
    required this.nbTransactions,
    required this.evolution1AnPct,
    required this.annee,
  });
}

/// Limite de l'API : 100 requêtes/jour par adresse IP (fenêtre glissante).
/// On ne l'interroge donc jamais en masse (ex. colorer toute la carte
/// d'un coup) — uniquement à la demande, pour une commune précise que
/// l'utilisateur consulte, avec un cache mémoire pour ne pas reconsommer
/// le quota sur une commune déjà vue pendant la session.
class ValorisService {
  final Map<String, ValorisPrice?> _cache = {};

  /// [codeDepartement] est obligatoire (ex. "75") ; [codeInsee] permet
  /// d'affiner sur une commune précise (ex. "75056") si disponible, sinon
  /// l'API renvoie le prix médian de tout le département.
  /// Retourne `null` si aucune donnée n'est disponible (département non
  /// couvert type Alsace-Moselle, quota atteint, service indisponible,
  /// pas de réseau...) — l'appelant garde alors son repère indicatif en
  /// repli, sans jamais faire planter l'écran.
  Future<ValorisPrice?> fetchPrixMedian({required String codeDepartement, String? codeInsee}) async {
    if (codeDepartement.isEmpty) return null;
    if (codeInsee != null) {
      final local = PrixReferenceService.lookup(codeInsee);
      if (local != null) {
        return ValorisPrice(
          prixMedianM2: local.prixMedianM2,
          nbTransactions: local.nbVentes,
          evolution1AnPct: null,
          annee: null,
        );
      }
    }
    final cacheKey = '$codeDepartement:${codeInsee ?? ''}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    final uri = Uri.https('www.valoris-immo.fr', '/api/v1/prix-median', {
      'dept': codeDepartement,
      if (codeInsee != null && codeInsee.isNotEmpty) 'commune': codeInsee,
    });
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        _cache[cacheKey] = null;
        return null;
      }
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (data['success'] != true || data['statut'] != 'disponible') {
        _cache[cacheKey] = null;
        return null;
      }
      final price = ValorisPrice(
        prixMedianM2: (data['prix_median_m2'] as num?)?.toDouble() ?? 0,
        nbTransactions: (data['nb_transactions'] as num?)?.toInt() ?? 0,
        evolution1AnPct: (data['evolution_1an_pct'] as num?)?.toDouble(),
        annee: (data['annee'] as num?)?.toInt() ?? 0,
      );
      _cache[cacheKey] = price;
      return price;
    } catch (_) {
      // Erreur ponctuelle (réseau...) : pas mise en cache, contrairement à
      // un "non disponible" confirmé par l'API — on pourra réessayer.
      return null;
    }
  }
}
