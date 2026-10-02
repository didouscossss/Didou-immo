import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'formation_content.dart';
import 'formation_module_screen.dart';

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
///
/// Cet écran ne sert plus que de sommaire — une carte par module, qui ouvre
/// la lecture leçon par leçon ([FormationModuleScreen]), quiz de fin de
/// module compris. Avant, tout le contenu tenait empilé dans des accordéons
/// sur cette seule page : jugé pas assez agréable à lire malgré un contenu
/// déjà complet.
class FormationScreen extends StatelessWidget {
  const FormationScreen({super.key});

  int get _totalLessons => formationModules.fold(0, (sum, m) => sum + m.lessons.length);
  int get _totalQuizQuestions => formationModules.fold(0, (sum, m) => sum + m.quiz.length);

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
          const SizedBox(height: 24),
          Text(
            'Sommaire',
            style: AppTextStyles.serif(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Touche un module pour le lire, une leçon à la fois.',
            style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < formationModules.length; i++) _ModuleSummaryCard(module: formationModules[i], index: i),
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
          "construire un vrai patrimoine — avec un exemple chiffré à chaque module, 4 études de cas complètes, "
          "et un quiz de mise en situation à la fin de chaque module pour vérifier que c'est bien acquis.",
          style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.75)).copyWith(height: 1.5),
        ),
        const SizedBox(height: 14),
        Row(children: [
          _heroStat(Icons.view_module_outlined, '${formationModules.length} modules'),
          const SizedBox(width: 16),
          _heroStat(Icons.menu_book_outlined, '$_totalLessons leçons'),
          const SizedBox(width: 16),
          _heroStat(Icons.quiz_outlined, '$_totalQuizQuestions questions'),
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

class _ModuleSummaryCard extends StatelessWidget {
  final FormationModule module;
  final int index;
  const _ModuleSummaryCard({required this.module, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FormationModuleScreen(moduleIndex: index))),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: module.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(module.icon, size: 21, color: module.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${index + 1}. ${module.title}',
                style: AppTextStyles.serif(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 3),
              Text(
                module.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 6),
              Text(
                module.quiz.isEmpty
                    ? '${module.lessons.length} leçon${module.lessons.length > 1 ? 's' : ''}'
                    : '${module.lessons.length} leçons · quiz de ${module.quiz.length} questions',
                style: AppTextStyles.sans(fontSize: 11, fontWeight: FontWeight.w600, color: module.color),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 20, color: AppColors.ink.withValues(alpha: 0.35)),
        ]),
      ),
    );
  }
}
