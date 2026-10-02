import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/user_account_state.dart';
import '../../theme/app_theme.dart';
import '../paywall/paywall_screen.dart';
import 'formation_content.dart';
import 'formation_module_screen.dart';

/// Formation "Réussir son premier investissement locatif" — incluse avec
/// l'abonnement annuel (41,99 €/an), pas avec le mensuel ni les essais
/// gratuits (voir la discussion produit et `UserAccountState.hasFormationAccess`,
/// qui pose aussi un accès pour les comptes admin, pour pouvoir relire le
/// contenu sans payer).
///
/// Visible par tout le monde (plus réservée aux admins) : un compte sans
/// accès voit le sommaire complet (titres, nombre de leçons) pour se rendre
/// compte de ce que l'offre annuelle débloque, mais ne peut pas ouvrir un
/// module — touché, il redirige vers [PaywallScreen] plutôt que d'afficher
/// le contenu.
///
/// Cet écran ne sert que de sommaire — une carte par module, qui ouvre la
/// lecture leçon par leçon ([FormationModuleScreen]), quiz de fin de module
/// compris.
class FormationScreen extends StatelessWidget {
  const FormationScreen({super.key});

  int get _totalLessons => formationModules.fold(0, (sum, m) => sum + m.lessons.length);
  int get _totalQuizQuestions => formationModules.fold(0, (sum, m) => sum + m.quiz.length);

  @override
  Widget build(BuildContext context) {
    final account = context.watch<UserAccountState>();
    final hasAccess = account.hasFormationAccess;
    return Scaffold(
      appBar: AppBar(title: const Text('Formation complète')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAccessNotice(context, account),
          const SizedBox(height: 16),
          _buildHero(),
          const SizedBox(height: 24),
          Text(
            'Sommaire',
            style: AppTextStyles.serif(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            hasAccess
                ? 'Touche un module pour le lire, une leçon à la fois.'
                : "Débloque l'abonnement annuel pour lire les modules ci-dessous.",
            style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < formationModules.length; i++)
            _ModuleSummaryCard(module: formationModules[i], index: i, locked: !hasAccess),
        ],
      ),
    );
  }

  /// Trois états distincts : accès réel (abonnement annuel) confirmé en
  /// vert, aperçu admin signalé en doré (un admin sans abonnement annuel
  /// voit quand même tout le contenu, mais doit savoir que ce n'est QUE
  /// grâce à son statut admin, pas ce qu'un abonné annuel verrait en plus),
  /// et l'argumentaire de vente avec CTA direct vers [PaywallScreen] pour
  /// tous les autres.
  Widget _buildAccessNotice(BuildContext context, UserAccountState account) {
    final realAccess = account.isSubscribed && account.subscriptionPlan == 'yearly';
    if (realAccess) {
      return _notice(
        icon: Icons.check_circle_outline,
        color: AppColors.good,
        text: 'Incluse dans ton abonnement annuel — bonne lecture !',
      );
    }
    if (account.isAdmin) {
      return _notice(
        icon: Icons.visibility_outlined,
        color: AppColors.gold,
        text: "Aperçu admin — réservée aux abonnés annuels pour tout le monde d'autre.",
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lock_outline, size: 16, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Incluse avec l'abonnement annuel (41,99 €/an) — pas avec le mensuel ni les essais gratuits.",
              style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink.withValues(alpha: 0.8)),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
          icon: const Icon(Icons.workspace_premium_outlined, size: 16),
          label: const Text("Débloquer avec l'abonnement annuel"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
    );
  }

  Widget _notice({required IconData icon, required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
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
            child: Text('🎓 Incluse avec l\'abonnement annuel',
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
  final bool locked;
  const _ModuleSummaryCard({required this.module, required this.index, required this.locked});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => locked
          ? Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()))
          : Navigator.of(context).push(MaterialPageRoute(builder: (_) => FormationModuleScreen(moduleIndex: index))),
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: locked ? 0.6 : 1,
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
            Icon(
              locked ? Icons.lock_outline : Icons.chevron_right,
              size: 20,
              color: AppColors.ink.withValues(alpha: 0.35),
            ),
          ]),
        ),
      ),
    );
  }
}
