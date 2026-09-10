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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: active ? AppShadows.sm : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(o.icon, size: 18, color: active ? Colors.white : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    o.label,
                    style: AppTextStyles.sans(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active ? Colors.white : AppColors.textMuted,
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
