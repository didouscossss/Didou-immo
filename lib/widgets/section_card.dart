import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Carte thématique légère — fond surface, ombre très discrète, pas de
/// bordure : sépare visuellement les groupes de champs d'un onglet sans
/// reproduire l'effet "boîte" plus marqué (bordure visible) essayé — et
/// écarté par l'utilisateur — avant la refonte visuelle en cours. Widget
/// partagé plutôt que dupliqué par écran, pour que ce traitement reste
/// identique partout dans l'app (voir la maquette de référence fournie).
///
/// Un `Container` imbriqué qui utilisait déjà `AppColors.surface` (même
/// couleur que la carte) devient invisible une fois niché dedans — passer
/// ce genre de bloc à `AppColors.paperSecondary` le garde visible.
class SectionCard extends StatelessWidget {
  final List<Widget> children;
  const SectionCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}
