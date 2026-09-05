import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/referral_service.dart';
import '../../state/user_account_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/arrival_bounce.dart';

/// Un seul écran, deux usages : partager/saisir un code de parrainage (voir
/// le palier — accès gratuit à vie, `UserAccountState.qualifiedReferralsCount`),
/// ou saisir un code cadeau (accès gratuit).
class ReferralScreen extends StatefulWidget {
  final String uid;
  final String? myReferralCode;
  const ReferralScreen({super.key, required this.uid, this.myReferralCode});

  /// Le parrainage repose sur deux Cloud Functions (`applyReferralCode` et
  /// `activateSubscription`, voir `functions/index.js`) : la première
  /// rattache le filleul à son parrain au moment où le code est saisi, la
  /// seconde pose le départ du décompte des 6 mois au moment où
  /// l'abonnement est activé (voir `ReferralService`). Repasser ce flag à
  /// `false` masque l'écran sans rien perdre côté données si jamais l'une
  /// des deux venait à ne plus être déployée.
  static const bool referralEnabled = true;

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _referral = ReferralService();
  final _parrainageController = TextEditingController();
  final _cadeauController = TextEditingController();
  String? _parrainageMessage;
  String? _cadeauMessage;
  bool _loadingParrainage = false;
  bool _loadingCadeau = false;

  Future<void> _applyParrainage() async {
    if (_parrainageController.text.trim().isEmpty) return;
    setState(() => _loadingParrainage = true);
    String? error;
    try {
      error = await _referral.applyReferralCode(_parrainageController.text);
    } catch (_) {
      error = "Une erreur est survenue, réessaie dans un instant.";
    }
    if (!mounted) return;
    setState(() {
      _loadingParrainage = false;
      _parrainageMessage = error ?? 'Code appliqué !';
    });
  }

  Future<void> _applyCadeau() async {
    if (_cadeauController.text.trim().isEmpty) return;
    setState(() => _loadingCadeau = true);
    String? error;
    try {
      error =
          await _referral.redeemAccessCode(widget.uid, _cadeauController.text);
    } catch (_) {
      error = "Une erreur est survenue, réessaie dans un instant.";
    }
    if (!mounted) return;
    setState(() {
      _loadingCadeau = false;
      _cadeauMessage = error ?? 'App débloquée gratuitement, profite-en !';
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<UserAccountState>();
    return Scaffold(
      appBar: AppBar(
          title: Text(ReferralScreen.referralEnabled ? 'Codes & parrainage' : 'Code cadeau')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (ReferralScreen.referralEnabled) ...[
            if (account.grantedFreeViaReferral)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.good.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: AppColors.good, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Palier atteint : accès illimité offert à vie, merci d'avoir fait connaître l'app !",
                        style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              )
            else if (widget.myReferralCode != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${account.qualifiedReferralsCount} / ${account.referralMilestoneThreshold} '
                      'parrainages qualifiés',
                      style: AppTextStyles.sans(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Un parrainage est qualifié quand ton filleul reste abonné en continu "
                      "pendant au moins 6 mois. Atteins ${account.referralMilestoneThreshold} "
                      "parrainages qualifiés et tu passes en accès illimité à vie, gratuitement.",
                      style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            if (widget.myReferralCode != null) ...[
              Text('Ton code de parrainage',
                  style: AppTextStyles.sans(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.myReferralCode!,
                        style: AppTextStyles.mono(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink)),
                    Icon(Icons.share, size: 18, color: AppColors.ink),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Partage-le : chaque filleul qui reste abonné en continu pendant au moins "
                "6 mois compte dans ton palier de parrainage, ci-dessus.",
                style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 28),
            ],
            Text('J\'ai un code de parrainage',
                style: AppTextStyles.sans(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(
              "Ton parrainage compte pour le palier de la personne qui t'a invité·e, une "
              "fois que tu restes abonné·e en continu pendant au moins 6 mois.",
              style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _parrainageController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'DIDOU-XXXX',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ArrivalBounce(
                  active: !_loadingParrainage,
                  child: ElevatedButton(
                    onPressed: _loadingParrainage ? null : _applyParrainage,
                    child: const Text('Valider'),
                  ),
                ),
              ],
            ),
            if (_parrainageMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_parrainageMessage!,
                    style: const TextStyle(fontSize: 12.5)),
              ),
            const SizedBox(height: 28),
          ],
          const Text('J\'ai un code cadeau',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cadeauController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Code reçu',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ArrivalBounce(
                active: !_loadingCadeau,
                child: ElevatedButton(
                  onPressed: _loadingCadeau ? null : _applyCadeau,
                  child: const Text('Valider'),
                ),
              ),
            ],
          ),
          if (_cadeauMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child:
                  Text(_cadeauMessage!, style: const TextStyle(fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}
