import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../services/commune_catalog_service.dart';
import '../../services/valoris_service.dart';
import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculations.dart';
import '../../utils/formatters.dart';
import '../../widgets/compare_bar.dart';
import '../../widgets/score_badge.dart';
import '../../widgets/section_title.dart';

/// Point sélectionnable sur la carte — unifie les 96 préfectures
/// (`CityRef`) et les communes ≥1500 habitants du catalogue
/// (`CommunePoint`). Aucune des deux ne porte de prix inventé : seul un
/// vrai prix VALORIS/DVF, chargé à la demande au tap, peut colorer un
/// point — avant ça, tous les points sont neutres, préfectures comprises.
class _SelCity {
  final String key;
  final String nom;
  final String codeDepartement;
  final String codeInsee;
  final double lat, lon;
  final bool isPrefecture;
  final double? staticLoyerM2;
  final bool tension;

  const _SelCity({
    required this.key,
    required this.nom,
    required this.codeDepartement,
    required this.codeInsee,
    required this.lat,
    required this.lon,
    required this.isPrefecture,
    this.staticLoyerM2,
    this.tension = false,
  });

  factory _SelCity.fromCityRef(CityRef c) => _SelCity(
        key: 'pref:${c.name}',
        nom: c.name,
        codeDepartement: c.codeDepartement,
        codeInsee: c.codeInsee,
        lat: c.lat,
        lon: c.lon,
        isPrefecture: true,
        // Le loyer n'a pas d'équivalent DVF (qui ne couvre que les ventes) :
        // pas de source gratuite temps réel, on garde cette estimation
        // indicative, toujours clairement labellisée comme telle dans l'UI.
        staticLoyerM2: c.loyerM2,
        tension: c.tension,
      );

  factory _SelCity.fromCommunePoint(CommunePoint p, {double? loyerM2Estime}) => _SelCity(
        key: 'commune:${p.codeInsee}',
        nom: p.nom,
        codeDepartement: p.codeDepartement,
        codeInsee: p.codeInsee,
        lat: p.lat,
        lon: p.lon,
        isPrefecture: false,
        staticLoyerM2: loyerM2Estime,
      );
}

/// Onglet "Carte" — carte de France interactive avec un repère par
/// département (préfectures) et, en zoomant, toutes les communes ≥1500
/// habitants (catalogue chargé une fois, voir `commune_catalog_service.dart`).
///
/// Aucun prix n'est affiché par défaut : le prix réel (VALORIS/DVF) n'est
/// chargé qu'à la demande, pour une ville tapée sur la carte — l'API est
/// limitée à 100 requêtes/jour par IP, donc hors de question de
/// l'interroger pour des milliers de points d'un coup. Tant qu'on n'a pas
/// tapé sur un point, il reste neutre (aucune estimation inventée).
class CarteScreen extends StatefulWidget {
  const CarteScreen({super.key});

  @override
  State<CarteScreen> createState() => _CarteScreenState();
}

const _maxSelection = 6;
const _zoomAffichageCommunes = 7.5;
const _maxCommunesAffichees = 400;

class _CarteScreenState extends State<CarteScreen> {
  final Set<String> _selected = {};
  final ValorisService _valoris = ValorisService();
  final CommuneCatalogService _catalogService = CommuneCatalogService();
  final Map<String, ValorisPrice?> _live = {};
  final Set<String> _loading = {};
  final MapController _mapController = MapController();

  List<CommunePoint> _catalog = [];
  bool _catalogLoading = true;
  MapCamera? _camera;

  @override
  void initState() {
    super.initState();
    _catalogService.load().then((list) {
      if (!mounted) return;
      setState(() {
        _catalog = list;
        _catalogLoading = false;
      });
    });
  }

  void _toggle(_SelCity city) {
    setState(() {
      if (_selected.contains(city.key)) {
        _selected.remove(city.key);
        return;
      }
      if (_selected.length >= _maxSelection) return;
      _selected.add(city.key);
    });
    if (_selected.contains(city.key) && !_live.containsKey(city.key)) {
      _fetchLive(city);
    }
  }

  Future<void> _fetchLive(_SelCity city) async {
    if (city.codeDepartement.isEmpty) return;
    setState(() => _loading.add(city.key));
    final price = await _valoris.fetchPrixMedian(
      codeDepartement: city.codeDepartement,
      codeInsee: city.codeInsee.isNotEmpty ? city.codeInsee : null,
    );
    if (!mounted) return;
    setState(() {
      _live[city.key] = price;
      _loading.remove(city.key);
    });
  }

  double? _effectivePrixM2(_SelCity c) => _live[c.key]?.prixMedianM2;

  /// Estimation de loyer pour une commune du catalogue (sans repère propre) :
  /// reprend celui de la préfecture de son département, sinon la moyenne
  /// nationale — cohérent avec le rattachement déjà fait pour l'onglet
  /// Marché (`nearestReference`).
  double _loyerEstimePourDepartement(String codeDepartement) {
    final pref = frenchCities.where((c) => c.codeDepartement == codeDepartement);
    return pref.isNotEmpty ? pref.first.loyerM2 : nationalAvg.loyerM2;
  }

  List<_SelCity> _villesVisibles() {
    final prefectures = frenchCities.map(_SelCity.fromCityRef).toList();
    final camera = _camera;
    if (camera == null || camera.zoom < _zoomAffichageCommunes || _catalog.isEmpty) {
      return prefectures;
    }
    final bounds = camera.visibleBounds;
    final nomsPrefectures = frenchCities.map((c) => c.name).toSet();
    final communesVisibles = _catalog
        .where((c) => !nomsPrefectures.contains(c.nom) && bounds.contains(LatLng(c.lat, c.lon)))
        .toList()
      ..sort((a, b) => b.population.compareTo(a.population));
    final communes = communesVisibles
        .take(_maxCommunesAffichees)
        .map((p) => _SelCity.fromCommunePoint(p, loyerM2Estime: _loyerEstimePourDepartement(p.codeDepartement)))
        .toList();
    return [...prefectures, ...communes];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    final refCity = state.refInfoAjuste?.ref;
    final villes = _villesVisibles();

    final prixConnus = villes.map(_effectivePrixM2).whereType<double>().toList();
    final prixMin = prixConnus.isEmpty ? 0.0 : prixConnus.reduce((a, b) => a < b ? a : b);
    final prixMax = prixConnus.isEmpty ? 1.0 : prixConnus.reduce((a, b) => a > b ? a : b);
    Color priceColor(double? prixM2) {
      if (prixM2 == null) return AppColors.ink.withValues(alpha: 0.25);
      final t = prixMax > prixMin ? ((prixM2 - prixMin) / (prixMax - prixMin)).clamp(0.0, 1.0) : 0.5;
      return Color.lerp(AppColors.accent, AppColors.alert, t)!;
    }

    final selectedCities = villes.where((c) => _selected.contains(c.key)).toList()
      ..sort((a, b) => (_effectivePrixM2(b) ?? -1).compareTo(_effectivePrixM2(a) ?? -1));
    final anyLiveData = _live.values.any((v) => v != null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SectionTitle('Carte des prix'),
        Text(
          _catalogLoading
              ? 'Chargement des communes de France (une fois, mis en cache ensuite)...'
              : 'Tape un point pour charger son vrai prix (VALORIS / DVF) — zoome pour voir les communes (≥1500 hab.)',
          style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 12),
        if (refCity != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(Icons.push_pin_outlined, size: 13, color: AppColors.gold),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Repère du bien en cours : ${refCity.name} (entouré en doré sur la carte)',
                    style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.6))),
              ),
            ]),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 340,
            decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(46.6, 2.4),
                initialZoom: 5.2,
                minZoom: 4,
                maxZoom: 13,
                onPositionChanged: (camera, hasGesture) => setState(() => _camera = camera),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.didouimmo.rendement',
                ),
                MarkerLayer(
                  markers: villes.map((c) {
                    final selected = _selected.contains(c.key);
                    final isRef = refCity != null && refCity.name == c.nom;
                    final size = selected ? 22.0 : (c.isPrefecture ? 14.0 : 9.0);
                    return Marker(
                      point: LatLng(c.lat, c.lon),
                      width: 32,
                      height: 32,
                      child: GestureDetector(
                        onTap: () => _toggle(c),
                        // `opaque` : sans ça, la zone cliquable réelle se
                        // limite au petit disque visible (parfois 9px), pas
                        // aux 32x32 du marqueur — beaucoup trop dur à viser
                        // précisément (le `Center` ne fait pas remonter les
                        // taps hors du disque tant que le comportement par
                        // défaut `deferToChild` est utilisé).
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: priceColor(_effectivePrixM2(c)),
                              border: Border.all(
                                color: isRef ? AppColors.gold : Colors.white,
                                width: isRef ? 2.5 : 1.5,
                              ),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Text('Moins cher', style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.5))),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(colors: [AppColors.accent, AppColors.alert]),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text('Plus cher', style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.5))),
          ]),
        ),
        const SizedBox(height: 8),
        Text(
          selectedCities.isEmpty
              ? 'Sélectionne jusqu\'à $_maxSelection villes sur la carte pour comparer leurs prix.'
              : '${selectedCities.length} ville${selectedCities.length > 1 ? 's' : ''} sélectionnée${selectedCities.length > 1 ? 's' : ''}',
          style: AppTextStyles.sans(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.ink),
        ),
        if (selectedCities.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selectedCities.map((c) {
              final loading = _loading.contains(c.key);
              final live = _live[c.key];
              return Chip(
                avatar: loading
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(live != null ? Icons.verified_outlined : Icons.info_outline,
                        size: 14, color: live != null ? AppColors.accent : AppColors.ink.withValues(alpha: 0.35)),
                label: Text(c.nom, style: AppTextStyles.sans(fontSize: 11.5)),
                onDeleted: () => _toggle(c),
                deleteIconColor: AppColors.ink.withValues(alpha: 0.4),
                backgroundColor: AppColors.paper,
                side: BorderSide(color: AppColors.border),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (selectedCities.any((c) => _effectivePrixM2(c) != null))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CompareBar(
                  label: 'Prix au m² (€)',
                  values: selectedCities
                      .where((c) => _effectivePrixM2(c) != null)
                      .map((c) => CompareBarValue(c.nom, _effectivePrixM2(c)!))
                      .toList(),
                  formatFn: eur,
                  color: AppColors.accent,
                ),
                CompareBar(
                  label: 'Loyer au m² (€, estimation)',
                  values: selectedCities
                      .where((c) => c.staticLoyerM2 != null)
                      .map((c) => CompareBarValue(c.nom, c.staticLoyerM2!))
                      .toList(),
                  formatFn: eur,
                  color: AppColors.gold,
                ),
              ]),
            ),
          const SizedBox(height: 16),
          ...selectedCities.map((c) => _cityVerdictCard(c)),
        ],
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 13, color: AppColors.ink.withValues(alpha: 0.5))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              anyLiveData
                  ? 'Prix marqués ✓ : données réelles VALORIS / DVF — Licence Ouverte (Etalab). Loyers : estimation indicative (DVF ne couvre que les ventes, pas les locations). Vérifie les données locales réelles avant de décider. Fond de carte © OpenStreetMap contributors.'
                  : 'Aucun prix affiché par défaut — tape une ville pour charger son vrai prix (VALORIS / DVF, données réelles des ventes notariées). Fond de carte © OpenStreetMap contributors.',
              style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _cityVerdictCard(_SelCity c) {
    final live = _live[c.key];
    final prix = _effectivePrixM2(c);
    if (prix == null) {
      final loading = _loading.contains(c.key);
      return Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Text(c.nom, style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loading ? 'Recherche du prix en cours...' : 'Aucune donnée de prix disponible pour cette commune.',
              style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.5)),
            ),
          ),
        ]),
      );
    }
    final cityForScore = CityRef(c.nom, prix, c.staticLoyerM2 ?? nationalAvg.loyerM2, c.tension, c.lat, c.lon, c.codeDepartement);
    final invest = computeCityInvestScore(cityForScore, evolution1AnPct: live?.evolution1AnPct);
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ScoreBadge(score: invest.score, label: invest.label, color: colorFromHex(invest.colorHex), size: BadgeSize.sm),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.nom, style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
              Text(invest.label, style: AppTextStyles.sans(fontSize: 11.5, color: colorFromHex(invest.colorHex))),
            ]),
          ),
          if (live != null)
            Text('${live.nbTransactions} ventes (${live.annee})',
                style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.4))),
        ]),
        const SizedBox(height: 10),
        ...invest.raisons.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.ink.withValues(alpha: 0.3))),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(r, style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.7)))),
              ]),
            )),
      ]),
    );
  }
}
