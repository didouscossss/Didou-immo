import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Panneau "Méthodologie" — équivalent de `MethodologieModal` du prototype.
class MethodologieSheet extends StatelessWidget {
  final VoidCallback onClose;
  const MethodologieSheet({super.key, required this.onClose});

  static const _items = [
    (
      title: 'Localisation',
      body: "La recherche de commune interroge l'API officielle geo.api.gouv.fr (IGN/INSEE) — gratuite, sans clé, sans limite. Aucun village n'est codé en dur.",
    ),
    (
      title: 'Repères de prix',
      body: "Rattachés à une petite liste de grandes villes de référence, ajustés par typologie de logement. Pour une commune non référencée, l'app retombe sur le département ou une moyenne nationale, clairement indiquée.",
    ),
    (
      title: 'Fiscalité',
      body: "Barèmes simplifiés (TMI + 17,2 % de prélèvements sociaux, abattements plus-value du régime des particuliers). Les cas LMNP réel et SCI à l'IS sont approximés.",
    ),
    (
      title: "Score d'investissement",
      body: "Un indicateur de comparaison interne (rendement, cash-flow, écart au marché, occupation), pas une note officielle ni un conseil financier.",
    ),
    (
      title: 'Limites',
      body: "Aucun de ces calculs ne remplace l'avis d'un notaire, d'un expert-comptable ou d'un courtier. Vérifie toujours les chiffres avant une décision d'achat.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Méthodologie', style: AppTextStyles.serif(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        InkWell(
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.border),
                            child: const Icon(Icons.close, size: 15, color: AppColors.ink),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      ..._items.map((it) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.title, style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
                                const SizedBox(height: 4),
                                Text(it.body, style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.65))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
