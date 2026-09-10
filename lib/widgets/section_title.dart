import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Titre de section — pastille d'icône colorée + titre en gras, inspiré
/// d'une maquette de référence envoyée par l'utilisateur (fond clair,
/// pastilles carrées arrondies colorées par section plutôt qu'un bandeau
/// dégradé). Remplace l'ancienne bande dégradée pleine largeur/pastille de
/// texte seul : l'icône donne un repère visuel immédiat par section, sans
/// dépendre de la couleur du texte lui-même.
class SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const SectionTitle(this.text, {super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppTextStyles.serif(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ),
      ]),
    );
  }
}
