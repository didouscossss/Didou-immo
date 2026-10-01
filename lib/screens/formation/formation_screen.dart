import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'formation_content.dart';

/// Formation payante "Réussir son premier investissement locatif" — 59 €,
/// paiement unique (pas un abonnement, voir la discussion produit).
///
/// Pas encore vendue : aucun flux de paiement n'est branché ici. Le but de
/// cette première version est de pouvoir relire/ajuster le contenu avant de
/// décider comment le vendre — d'où l'accès réservé aux comptes admin
/// (`UserAccountState.isAdmin`, voir `AccountScreen`) plutôt qu'un vrai
/// paywall. Une fois le contenu validé, ce sera soit un paywall Stripe
/// dédié (one-shot, pas un abonnement), soit un déblocage manuel via un
/// code, selon ce que l'utilisateur choisira à ce moment-là.
class FormationScreen extends StatelessWidget {
  const FormationScreen({super.key});

  int get _totalLessons => formationModules.fold(0, (sum, m) => sum + m.lessons.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formation complète')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAdminNotice(),
          const SizedBox(height: 16),
          _buildHero(),
          const SizedBox(height: 28),
          for (int i = 0; i < formationModules.length; i++) _ModuleCard(module: formationModules[i], index: i),
        ],
      ),
    );
  }

  Widget _buildAdminNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.visibility_outlined, size: 16, color: AppColors.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "Visible uniquement par les comptes admin pour le moment — le paiement n'est pas encore branché.",
            style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink.withValues(alpha: 0.75)),
          ),
        ),
      ]),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.sectionBandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.good, borderRadius: BorderRadius.circular(999)),
            child: Text('59 € · paiement unique',
                style: AppTextStyles.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(
          'Réussir son premier investissement locatif',
          style: AppTextStyles.serif(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          "Du tout premier réflexe jusqu'à la revente : trouver le bon bien, choisir sa zone, chiffrer sa "
          "rentabilité, le financer, gérer les travaux, comprendre la fiscalité, gérer le quotidien, et "
          "construire un vrai patrimoine sur le temps long.",
          style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.75)).copyWith(height: 1.5),
        ),
        const SizedBox(height: 14),
        Row(children: [
          _heroStat(Icons.view_module_outlined, '${formationModules.length} modules'),
          const SizedBox(width: 16),
          _heroStat(Icons.menu_book_outlined, '$_totalLessons leçons'),
          const SizedBox(width: 16),
          _heroStat(Icons.all_inclusive, 'Accès à vie'),
        ]),
      ]),
    );
  }

  Widget _heroStat(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppColors.accent),
      const SizedBox(width: 5),
      Text(label, style: AppTextStyles.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink.withValues(alpha: 0.7))),
    ]);
  }
}

class _ModuleCard extends StatelessWidget {
  final FormationModule module;
  final int index;
  const _ModuleCard({required this.module, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: module.color,
          collapsedIconColor: AppColors.ink.withValues(alpha: 0.4),
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: module.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(module.icon, size: 18, color: module.color),
          ),
          title: Text('${index + 1}. ${module.title}',
              style: AppTextStyles.serif(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
          subtitle: Text(module.subtitle, style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.55))),
          children: [
            for (final lesson in module.lessons) _LessonBlock(lesson: lesson, color: module.color),
          ],
        ),
      ),
    );
  }
}

class _LessonBlock extends StatelessWidget {
  final FormationLesson lesson;
  final Color color;
  const _LessonBlock({required this.lesson, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(top: 7, right: 10),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(
              child: Text(lesson.title, style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ),
          ]),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              lesson.body,
              style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.78)).copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
