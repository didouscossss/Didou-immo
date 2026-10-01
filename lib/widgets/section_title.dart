import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Titre de section — pastille d'icône colorée + titre en gras, inspiré
/// d'une maquette de référence envoyée par l'utilisateur (fond clair,
/// pastilles carrées arrondies colorées par section plutôt qu'un bandeau
/// dégradé plein). L'icône donne un repère visuel immédiat par section,
/// sans dépendre de la couleur du texte lui-même.
///
/// Le tout est posé sur le bandeau dégradé par mode (terre cuite en
/// novice, turquoise/cyan en avancé — [AppColors.sectionBandGradient]) :
/// il redonne le repère "dans quel mode je suis" que ce bandeau apportait
/// avant l'introduction des pastilles, sans changer la disposition
/// icône + titre elle-même.
class SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  /// Repère "rempli pour CE bien" — `null` (par défaut) n'affiche aucun
  /// badge, pour les encarts dont tous les champs ont un défaut raisonnable
  /// et qu'on ne force donc pas à "compléter". `true`/`false` affiche un
  /// badge coché/vide en bout de titre : coché dès qu'au moins un champ clé
  /// de l'encart diffère de l'exemple pré-rempli (voir
  /// `PropertyInput.defaultForm`) — demandé par l'utilisateur pour voir, en
  /// un coup d'œil, quels encarts il a déjà adaptés à SON bien et lesquels
  /// restent encore sur l'exemple de démonstration.
  final bool? done;

  const SectionTitle(this.text, {super.key, required this.icon, required this.color, this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.sectionBandGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTextStyles.serif(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ),
          if (done != null) _DoneBadge(done: done!),
        ]),
      ),
    );
  }
}

class _DoneBadge extends StatelessWidget {
  final bool done;
  const _DoneBadge({required this.done});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: done ? 'Renseigné pour ce bien' : 'Encore sur les valeurs d\'exemple',
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? AppColors.good : Colors.transparent,
          border: Border.all(color: done ? AppColors.good : AppColors.ink.withValues(alpha: 0.25), width: 1.5),
        ),
        child: done ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
      ),
    );
  }
}
