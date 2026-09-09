import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    // Pastille (largeur ajustée au texte, pas pleine largeur) plutôt qu'une
    // bande qui s'étire sur toute la largeur de la carte : c'est ce
    // contraste de largeur avec le contenu en dessous (champs, boutons...
    // eux bien plus larges) qui fait ressortir le titre — une bande pleine
    // largeur donnait l'impression que tout avait la même largeur,
    // "linéaire" du titre jusqu'au bas de la section.
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: AppColors.sectionBandGradient,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(text, style: AppTextStyles.serif(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ),
      ),
    );
  }
}
