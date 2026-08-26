import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/calculations.dart';

/// Synthèse "ce bien a l'air solide / points à surveiller" — équivalent
/// de `VerdictCard`.
class VerdictCard extends StatelessWidget {
  final CoreResult core;
  final PropertyInput form;
  const VerdictCard({super.key, required this.core, required this.form});

  @override
  Widget build(BuildContext context) {
    final good = <String>[];
    final warn = <String>[];
    if (core.cashflowMensuel >= 0) {
      good.add('Le loyer couvre le crédit et les charges chaque mois.');
    } else {
      warn.add('Le cash-flow est négatif : il faudra sortir de l\'argent de ta poche chaque mois.');
    }
    if (core.net >= 4) {
      good.add("La rentabilité nette est correcte pour ce type d'investissement.");
    } else {
      warn.add("La rentabilité nette est plutôt faible, compare avec d'autres biens.");
    }
    if (!core.capaciteOk) {
      warn.add("La mensualité dépasse ta capacité d'emprunt estimée (35 % d'endettement).");
    }
    if (dpeInfo[form.dpe]?.banIssue != null) {
      warn.add('Le DPE de ce bien limite ou limitera bientôt sa location.');
    }
    final isGood = warn.isEmpty;
    final items = [...good, ...warn];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isGood ? AppColors.accent : AppColors.alert).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isGood ? AppColors.accent : AppColors.alert).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 15, color: isGood ? AppColors.accent : AppColors.alert),
              const SizedBox(width: 8),
              Text(
                isGood ? "Ce bien a l'air plutôt solide" : 'Quelques points à surveiller',
                style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: warn.contains(t) ? AppColors.alert : AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t, style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.8))),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
