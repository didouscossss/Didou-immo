import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculations.dart';
import '../../utils/formatters.dart';
import '../../widgets/compare_bar.dart';
import '../../widgets/section_title.dart';

/// Onglet "Carte" — carte de France des repères de prix au m² (un point par
/// département), avec sélection de plusieurs villes pour les comparer.
class CarteScreen extends StatefulWidget {
  const CarteScreen({super.key});

  @override
  State<CarteScreen> createState() => _CarteScreenState();
}

const _maxSelection = 6;

class _CarteScreenState extends State<CarteScreen> {
  final Set<String> _selected = {};

  void _toggle(String name) {
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else if (_selected.length < _maxSelection) {
        _selected.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    final refCity = state.refInfoAjuste?.ref;

    final prixMin = frenchCities.map((c) => c.prixM2).reduce((a, b) => a < b ? a : b);
    final prixMax = frenchCities.map((c) => c.prixM2).reduce((a, b) => a > b ? a : b);
    Color priceColor(double prixM2) {
      final t = prixMax > prixMin ? ((prixM2 - prixMin) / (prixMax - prixMin)).clamp(0.0, 1.0) : 0.5;
      return Color.lerp(AppColors.accent, AppColors.alert, t)!;
    }

    final selectedCities = frenchCities.where((c) => _selected.contains(c.name)).toList()
      ..sort((a, b) => b.prixM2.compareTo(a.prixM2));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SectionTitle('Carte des prix'),
        Text('Un repère par département — tape sur un point pour le comparer',
            style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.45))),
        const SizedBox(height: 12),
        if (refCity != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.push_pin_outlined, size: 13, color: AppColors.gold),
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
              options: const MapOptions(
                initialCenter: LatLng(46.6, 2.4),
                initialZoom: 5.2,
                minZoom: 4,
                maxZoom: 11,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.didouimmo.rendement',
                ),
                MarkerLayer(
                  markers: frenchCities.map((c) {
                    final selected = _selected.contains(c.name);
                    final isRef = refCity?.name == c.name;
                    final size = selected ? 22.0 : 14.0;
                    return Marker(
                      point: LatLng(c.lat, c.lon),
                      width: 32,
                      height: 32,
                      child: GestureDetector(
                        onTap: () => _toggle(c.name),
                        child: Center(
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: priceColor(c.prixM2),
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
            children: selectedCities.map((c) => Chip(
                  label: Text(c.name, style: AppTextStyles.sans(fontSize: 11.5)),
                  onDeleted: () => _toggle(c.name),
                  deleteIconColor: AppColors.ink.withValues(alpha: 0.4),
                  backgroundColor: AppColors.paper,
                  side: BorderSide(color: AppColors.border),
                )).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CompareBar(
                label: 'Prix au m² (€)',
                values: selectedCities.map((c) => CompareBarValue(c.name, c.prixM2)).toList(),
                formatFn: eur,
                color: AppColors.accent,
              ),
              CompareBar(
                label: 'Loyer au m² (€)',
                values: selectedCities.map((c) => CompareBarValue(c.name, c.loyerM2)).toList(),
                formatFn: eur,
                color: AppColors.gold,
              ),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 13, color: AppColors.ink.withValues(alpha: 0.5))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Repères de prix indicatifs et arrondis, un point par département (généralement sa préfecture) — vérifie les données locales réelles (notaires, observatoires des loyers) avant de décider. Fond de carte © OpenStreetMap contributors.',
              style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
            ),
          ),
        ]),
      ],
    );
  }
}
