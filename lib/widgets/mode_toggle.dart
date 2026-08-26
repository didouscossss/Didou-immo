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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: options.map((o) {
          final active = mode == o.mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: active
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 3, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(o.icon, size: 15, color: active ? AppColors.accent : AppColors.ink.withValues(alpha: 0.5)),
                    const SizedBox(width: 6),
                    Text(
                      o.label,
                      style: AppTextStyles.sans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: active ? AppColors.accent : AppColors.ink.withValues(alpha: 0.5),
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
