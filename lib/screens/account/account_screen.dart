import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../../state/user_account_state.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_screen.dart';
import '../paywall/paywall_screen.dart';
import '../referral/referral_screen.dart';

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
            ElevatedButton.icon(
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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ReferralScreen(uid: user.uid, myReferralCode: account.referralCode),
            )),
            icon: const Icon(Icons.card_giftcard_outlined),
            label: const Text('Parrainage & codes cadeaux'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.border),
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
                side: const BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          const SizedBox(height: 28),
          TextButton(
            onPressed: () => account.signOut(),
            child: Text('Se déconnecter', style: AppTextStyles.sans(fontSize: 13, color: AppColors.alert)),
          ),
        ],
      ),
    );
  }
}
