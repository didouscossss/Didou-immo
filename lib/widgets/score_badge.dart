import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeSize { sm, md }

/// Pastille de score — équivalent de `ScoreBadge`.
class ScoreBadge extends StatelessWidget {
  final int score;
  final String label;
  final Color color;
  final BadgeSize size;

  const ScoreBadge({
    super.key,
    required this.score,
    required this.label,
    required this.color,
    this.size = BadgeSize.md,
  });

  @override
  Widget build(BuildContext context) {
    final dim = size == BadgeSize.sm ? 36.0 : 56.0;
    final fontSize = size == BadgeSize.sm ? 12.0 : 17.0;
    final badge = Container(
      width: dim,
      height: dim,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(score.toString(), style: AppTextStyles.mono(fontSize: fontSize, fontWeight: FontWeight.bold, color: color)),
    );
    if (size == BadgeSize.sm) return badge;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Score d'investissement", style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
            Text(label, style: AppTextStyles.sans(fontSize: 11, color: color)),
          ],
        ),
      ],
    );
  }
}
