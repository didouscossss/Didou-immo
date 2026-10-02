import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../../state/user_account_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/arrival_bounce.dart';
import '../admin/admin_screen.dart';
import '../legal/legal_screens.dart';
import '../paywall/paywall_screen.dart';
import '../referral/referral_screen.dart';
import '../suggestions/suggestions_screen.dart';

/// Écran "Compte" — statut d'abonnement, parrainage, déconnexion, et accès
/// à l'administration pour les comptes admin.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<UserAccountState>();
    final user = account.user;
    if (user == null) return const SizedBox.shrink();

    final statusLabel = account.isSubscribed
        ? 'Abonné·e — accès illimité'
        : account.grantedFreeViaReferral
            ? 'Accès illimité à vie (palier de parrainage atteint)'
            : account.grantedFree
                ? 'Accès gratuit (code cadeau)'
                : '${account.freeTrialsUsed}/${FirestoreService.freeTrialsLimit} biens gratuits utilisés';

    return Scaffold(
      appBar: AppBar(title: const Text('Mon compte')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(user.email ?? user.displayName ?? 'Compte', style: AppTextStyles.sans(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(statusLabel, style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          if (!account.isSubscribed && !account.grantedFree)
            ArrivalBounce(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Passer en illimité'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ReferralScreen(uid: user.uid, myReferralCode: account.referralCode),
            )),
            icon: const Icon(Icons.card_giftcard_outlined),
            label: Text(ReferralScreen.referralEnabled ? 'Parrainage & code cadeau' : 'Code cadeau'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SuggestionsScreen(uid: user.uid),
            )),
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Proposer une amélioration'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (account.isAdmin) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminScreen())),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Administration'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LegalHubScreen())),
            icon: const Icon(Icons.gavel_outlined),
            label: const Text('Informations légales'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 28),
          TextButton(
            onPressed: () async {
              // Cet écran est poussé au-dessus de `AppRoot` (qui bascule
              // déjà tout seul sur AuthScreen dès que `user` devient null) —
              // sans le pop, la route restait affichée par-dessus, avec le
              // `SizedBox.shrink()` ci-dessus : une page blanche.
              await account.signOut();
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: Text('Se déconnecter', style: AppTextStyles.sans(fontSize: 13, color: AppColors.alert)),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _confirmDeleteAccount(context, account),
            child: Text('Supprimer mon compte', style: AppTextStyles.sans(fontSize: 13, color: AppColors.alert)),
          ),
        ],
      ),
    );
  }

  /// Droit à l'effacement (RGPD) : confirmation, puis réauthentification —
  /// Firebase l'exige pour cette opération sensible si la connexion date
  /// un peu — avant d'effacer irréversiblement les données et le compte.
  Future<void> _confirmDeleteAccount(BuildContext context, UserAccountState account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer définitivement ton compte ?'),
        content: const Text(
          'Tous tes biens enregistrés et les données de ton compte seront effacés '
          'immédiatement. Cette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Supprimer', style: TextStyle(color: AppColors.alert)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    String? password;
    if (account.authProviderId == 'password') {
      password = await showDialog<String>(context: context, builder: (_) => const _PasswordPromptDialog());
      if (password == null || !context.mounted) return; // annulé
    }

    final error = await account.deleteAccount(password: password);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    // Cet écran est poussé au-dessus de `AppRoot` (qui bascule déjà tout
    // seul sur AuthScreen dès que `user` devient null) — sans le pop, la
    // route resterait affichée par-dessus le `SizedBox.shrink()` ci-dessus.
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }
}

/// Demande le mot de passe avant suppression d'un compte email/mot de
/// passe — nécessaire à la réauthentification exigée par Firebase.
class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog();

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirme ton mot de passe'),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Mot de passe'),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}
