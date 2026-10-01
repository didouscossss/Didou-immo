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
  /// et qu'on ne force donc pas à "compléter". Sinon `(done, total)` : le
  /// nombre de champs de l'encart qui diffèrent déjà de l'exemple pré-rempli
  /// (voir `PropertyInput.defaultForm`) sur le nombre total suivi — un
  /// badge "x/y" tant qu'il en manque, un check vert plein seulement une
  /// fois TOUS comptés. Un simple true/false à la première version se
  /// cochait dès qu'un seul champ sur plusieurs changeait (ex. le loyer
  /// dans un encart "Revenus & charges" qui en compte 6), ce qui pouvait
  /// faire croire un encart complet alors que d'autres champs restaient
  /// oubliés sur l'exemple — signalé par l'utilisateur, d'où le comptage.
  final (int done, int total)? progress;

  const SectionTitle(this.text, {super.key, required this.icon, required this.color, this.progress});

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
          if (progress != null) _DoneBadge(done: progress!.$1, total: progress!.$2),
        ]),
      ),
    );
  }
}

class _DoneBadge extends StatelessWidget {
  final int done;
  final int total;
  const _DoneBadge({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final complete = done >= total;
    // Un seul champ suivi (ex. "Informations générales" : juste le nom) :
    // le "x/y" serait toujours "0/1" ou "1/1", pas plus parlant qu'un
    // simple rond coché/vide — garde l'affichage le plus simple des deux.
    if (total <= 1) {
      return Tooltip(
        message: complete ? 'Renseigné pour ce bien' : "Encore sur l'exemple de démonstration",
        child: Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: complete ? AppColors.good : Colors.transparent,
            border: Border.all(color: complete ? AppColors.good : AppColors.ink.withValues(alpha: 0.25), width: 1.5),
          ),
          child: complete ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
        ),
      );
    }
    return Tooltip(
      message: complete
          ? 'Renseigné pour ce bien'
          : '$done champ${done > 1 ? 's' : ''} sur $total déjà adapté${done > 1 ? 's' : ''} à ton bien',
      child: Container(
        constraints: const BoxConstraints(minWidth: 30),
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: complete ? AppColors.good : AppColors.ink.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: complete ? null : Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
        ),
        child: complete
            ? const Icon(Icons.check, size: 13, color: Colors.white)
            : Text('$done/$total', style: AppTextStyles.mono(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.6))),
      ),
    );
  }
}
