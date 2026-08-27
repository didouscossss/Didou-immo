import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Petite icône "?" à poser à côté d'un champ technique — tape dessus pour
/// une définition courte en bas d'écran, sans quitter le formulaire (voir
/// aussi la fiche "Méthodologie", plus complète mais séparée du contexte).
class GlossaryIcon extends StatelessWidget {
  final String term;
  final String definition;
  const GlossaryIcon({super.key, required this.term, required this.definition});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _show(context),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(Icons.help_outline_rounded, size: 14, color: AppColors.ink.withValues(alpha: 0.4)),
      ),
    );
  }

  void _show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(16)),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.help_outline_rounded, size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(child: Text(term, style: AppTextStyles.serif(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink))),
              ]),
              const SizedBox(height: 10),
              Text(definition, style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.75))),
            ]),
          ),
        ),
      ),
    );
  }
}
