import 'package:flutter/material.dart';
import '../state/rendement_state.dart';
import '../theme/app_theme.dart';

/// Sélecteur novice / avancé — équivalent de `NiveauToggle`.
class NiveauToggle extends StatelessWidget {
  final NiveauMode niveau;
  final ValueChanged<NiveauMode> onChanged;
  const NiveauToggle({super.key, required this.niveau, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (mode: NiveauMode.novice, label: 'Novice', icon: Icons.auto_awesome_outlined),
      (mode: NiveauMode.avance, label: 'Avancé', icon: Icons.tune),
    ];
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final active = niveau == o.mode;
          return GestureDetector(
            onTap: () => onChanged(o.mode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(o.icon, size: 12, color: active ? Colors.white : AppColors.ink.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    o.label,
                    style: AppTextStyles.sans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: active ? Colors.white : AppColors.ink.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
