import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/calculations.dart';

/// Sélecteur longue durée / courte durée — équivalent de `ModeToggle`.
class ModeToggle extends StatelessWidget {
  final RentalMode mode;
  final ValueChanged<RentalMode> onChanged;
  const ModeToggle({super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (mode: RentalMode.longue, label: 'Longue durée', icon: Icons.apartment_outlined),
      (mode: RentalMode.courte, label: 'Courte durée', icon: Icons.bed_outlined),
    ];
    // État sélectionné : accent plein (vert novice / violet avancé) + texte
    // blanc — même logique que les autres sélecteurs de l'app (typologie,
    // Nu/Meublé, NiveauToggle) plutôt qu'un style propre à ce widget.
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.paperSecondary, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        children: options.map((o) {
          final active = mode == o.mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm - 3),
                  boxShadow: active ? AppShadows.sm : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(o.icon, size: 15, color: active ? Colors.white : AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      o.label,
                      style: AppTextStyles.sans(
                        fontSize: 12.5,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color: active ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
