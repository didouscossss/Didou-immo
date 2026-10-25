import 'package:flutter/material.dart';

import '../state/rendement_state.dart';
import '../theme/app_theme.dart';

/// Contenu de la pop-up affichée en changeant de profil (voir
/// [showNiveauInfoDialog]) — demandé par l'utilisateur : qu'un clic sur un
/// profil explique à quoi il sert et sa valeur ajoutée, pas seulement un
/// changement silencieux de libellé dans le sélecteur.
class _NiveauInfo {
  final String title;
  final IconData icon;
  final String tagline;
  final List<String> points;
  const _NiveauInfo({required this.title, required this.icon, required this.tagline, required this.points});
}

const Map<NiveauMode, _NiveauInfo> _niveauInfo = {
  NiveauMode.debutant: _NiveauInfo(
    title: 'Débutant',
    icon: Icons.auto_awesome_outlined,
    tagline: "Tu réalises ta première simulation ? Ce mode t'accompagne pas à pas, une chose à la fois.",
    points: [
      "Un assistant en 4 étapes guidées (le bien, revenus & charges, financement, résultat)",
      "Une explication sur chaque champ et chaque chiffre clé",
      "Des conseils contextuels de Didou au fil de la saisie",
      "Un verdict en langage clair à la fin : ce bien a l'air solide, ou à surveiller",
      "Un simulateur \"Et si...?\" pour voir si ce bien resterait viable face à un imprévu (taux qui monte, locataire qui part, travaux)",
    ],
  ),
  NiveauMode.intermediaire: _NiveauInfo(
    title: 'Intermédiaire',
    icon: Icons.tune,
    tagline: "Tu connais déjà les bases ? Tous les champs sur un seul écran, sans accompagnement superflu.",
    points: [
      "L'écran de saisie complet en une liste, pour aller vite",
      "Comparateur d'offres de prêt entre plusieurs banques",
      "Détail des régimes fiscaux et structures de détention",
      "Comparatif longue vs courte durée, et entre tes biens enregistrés",
    ],
  ),
  NiveauMode.experimente: _NiveauInfo(
    title: 'Expérimenté',
    icon: Icons.workspace_premium_outlined,
    tagline: "Tu veux aller plus loin ? Des outils pensés pour affiner une analyse, pas juste plus de champs.",
    points: [
      "Tout ce qu'offre le mode Intermédiaire",
      "Pondère toi-même le score (priorise cash-flow, rendement, marché...)",
      "Charges annexes avancées : assurance loyers impayés, provision gros travaux, CFE",
      "Seuils de rentabilité calculés automatiquement : jusqu'où le prix, le taux, le loyer ou l'occupation peuvent se dégrader avant un cash-flow négatif",
    ],
  ),
};

/// Affichée juste après avoir basculé sur [mode] (voir `NiveauToggle`) — un
/// simple "Compris" pour fermer, aucune confirmation requise : changer de
/// profil reste réversible à tout moment depuis le même sélecteur.
Future<void> showNiveauInfoDialog(BuildContext context, NiveauMode mode) {
  final info = _niveauInfo[mode]!;
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(info.icon, color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mode ${info.title}',
                style: AppTextStyles.serif(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            info.tagline,
            style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.7)).copyWith(height: 1.4),
          ),
          const SizedBox(height: 16),
          for (final point in info.points) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(point, style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.85)).copyWith(height: 1.4)),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Compris'),
          ),
        ]),
      ),
    ),
  );
}
