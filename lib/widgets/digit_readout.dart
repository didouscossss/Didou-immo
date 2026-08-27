import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

enum ReadoutSize { lg, md, sm }

/// Affichage chiffré en Space Mono — équivalent de `DigitReadout` du prototype.
class DigitReadout extends StatelessWidget {
  final double value;
  final String suffix;
  final Color? accent;
  final ReadoutSize size;

  const DigitReadout({
    super.key,
    required this.value,
    this.suffix = '%',
    this.accent,
    this.size = ReadoutSize.lg,
  });

  @override
  Widget build(BuildContext context) {
    final isNeg = value < 0;
    final display = '${isNeg ? '-' : ''}${fmt(value.abs(), 2)}';
    final color = isNeg ? AppColors.alert : (accent ?? AppColors.accent);
    final fontSize = switch (size) {
      ReadoutSize.lg => 44.0,
      ReadoutSize.md => 24.0,
      ReadoutSize.sm => 18.0,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(display, style: AppTextStyles.mono(fontSize: fontSize, fontWeight: FontWeight.w400, color: color)),
        const SizedBox(width: 4),
        Text(suffix, style: AppTextStyles.mono(fontSize: 13, color: color.withValues(alpha: 0.7))),
      ],
    );
  }
}
