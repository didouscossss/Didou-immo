import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CompareBarValue {
  final String name;
  final double value;
  const CompareBarValue(this.name, this.value);
}

/// Comparatif horizontal en barres — équivalent de `CompareBar`.
class CompareBar extends StatelessWidget {
  final String label;
  final List<CompareBarValue> values;
  final String Function(double) formatFn;
  final Color color;

  const CompareBar({
    super.key,
    required this.label,
    required this.values,
    required this.formatFn,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final max = values.map((v) => v.value).fold<double>(0.001, (a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.sans(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.ink.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          ...values.map((v) {
            final ratio = ((v.value > 0 ? v.value : 0) / max).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.6))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(builder: (context, constraints) {
                      final w = (constraints.maxWidth * ratio).clamp(16.0, constraints.maxWidth);
                      return Container(
                        height: 20,
                        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(6)),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: w,
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                          child: Text(formatFn(v.value),
                              style: AppTextStyles.mono(fontSize: 9, color: Colors.white)),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
