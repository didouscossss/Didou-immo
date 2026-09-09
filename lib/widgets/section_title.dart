import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final title = Text(text, style: AppTextStyles.serif(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink));
    // Bande dégradée terra cotta derrière chaque titre de section, en mode
    // novice uniquement pour l'instant (voir AppColors.sectionBandGradient
    // — le mode avancé reste inchangé, à traiter séparément).
    if (!AppColors.isNovice) {
      return Padding(padding: const EdgeInsets.only(bottom: 12), child: title);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: AppColors.sectionBandGradient,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: title,
      ),
    );
  }
}
