import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Conseil contextuel pour le mode "novice" — équivalent de `Tip`.
class Tip extends StatelessWidget {
  final String text;
  const Tip(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.lightbulb_outline, size: 14, color: AppColors.gold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }
}
