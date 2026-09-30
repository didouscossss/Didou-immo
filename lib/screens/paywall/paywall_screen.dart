import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:provider/provider.dart';

import '../../services/billing_service.dart';
import '../../services/firestore_service.dart';
import '../../services/web_nav/navigate_to.dart';
import '../../state/user_account_state.dart';
import '../../theme/app_theme.dart';
import '../legal/legal_screens.dart';

/// Affiché quand l'utilisateur a épuisé ses biens gratuits et n'est pas
/// encore abonné. Propose les deux offres (mensuelle / annuelle).
///
/// Deux circuits de paiement selon la plateforme, vers le même champ
/// `isSubscribed` Firestore (voir `UserAccountState`) : Google Play Billing
/// sur Android (`BillingService`), Stripe Checkout sur le web (`_buyWeb`,
/// pas de Play Billing hors Android) — un compte abonné via l'un des deux
/// est donc reconnu comme abonné sur l'autre, sans double paiement.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _billing = BillingService();
  List<ProductDetails> _products = [];
  bool _loading = true;
  bool _purchasing = false;
  String? _webError;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _billing.listenToPurchaseUpdates(onPurchase: _onPurchase, onError: (_) {
        if (mounted) setState(() => _purchasing = false);
      });
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    final available = await _billing.isAvailable();
    if (!available) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final response = await _billing.loadProducts();
    if (!mounted) return;
    setState(() {
      _products = response.productDetails;
      _loading = false;
    });
  }

  Future<void> _onPurchase(PurchaseDetails purchase) async {
    if (!mounted) return;
    final account = context.read<UserAccountState>();
    if (account.user != null) {
      await account.activateSubscription();
    }
    if (!mounted) return;
    setState(() => _purchasing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abonnement activé, merci !')));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _billing.dispose();
    super.dispose();
  }

  /// Abonnement côté web — pas de Google Play Billing sur navigateur, donc
  /// un paiement Stripe Checkout (voir `createStripeCheckoutSession` dans
  /// `functions/index.js`) à la place : la fonction renvoie l'URL de la
  /// page de paiement hébergée par Stripe, vers laquelle on redirige
  /// simplement le navigateur. `successUrl`/`cancelUrl` pointent toutes les
  /// deux vers la page courante (`Uri.base`) pour rester valables quel que
  /// soit le domaine de déploiement.
  ///
  /// Le webhook Stripe (pas ce client) confirme le paiement et active
  /// l'abonnement côté serveur — après la redirection de retour, un délai
  /// de quelques secondes avant que `isSubscribed` soit à jour est normal.
  Future<void> _buyWeb(String plan) async {
    setState(() {
      _purchasing = true;
      _webError = null;
    });
    try {
      final returnUrl = Uri.base.toString();
      final result = await FirebaseFunctions.instance.httpsCallable('createStripeCheckoutSession').call({
        'plan': plan,
        'successUrl': returnUrl,
        'cancelUrl': returnUrl,
      });
      final url = result.data['url'] as String?;
      if (url == null) throw Exception('URL de paiement manquante.');
      navigateTo(url);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _purchasing = false;
        _webError = "Impossible de lancer le paiement pour le moment. Réessaie dans un instant.";
      });
    }
  }

  /// Extrait la période de facturation ("/mois", "/an"...) depuis les
  /// données Google Play Billing — sans ça, les deux offres affichent le
  /// même nom ("Abonnement Illimité") et seul le prix diffère, impossible
  /// de savoir laquelle est mensuelle ou annuelle sans taper dessus.
  String? _billingPeriodSuffix(ProductDetails p) {
    if (p is! GooglePlayProductDetails) return null;
    final offers = p.productDetails.subscriptionOfferDetails;
    final index = p.subscriptionIndex;
    if (offers == null || index == null || index >= offers.length) return null;
    final phases = offers[index].pricingPhases;
    if (phases.isEmpty) return null;
    // Dernière phase : celle du prix récurrent normal (après un éventuel
    // essai gratuit ou tarif de lancement, si un jour configuré).
    final match = RegExp(r'^P(\d+)([MY])$').firstMatch(phases.last.billingPeriod);
    if (match == null) return null;
    final count = int.parse(match.group(1)!);
    final isYear = match.group(2) == 'Y';
    if (count == 1) return isYear ? '/an' : '/mois';
    return isYear ? '/$count ans' : '/$count mois';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passer en illimité')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Tu as utilisé tes ${FirestoreService.freeTrialsLimit} biens gratuits. Passe en illimité pour "
              "continuer à enregistrer et comparer autant de biens que tu veux.",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (kIsWeb) ...[
              // Pas de Google Play Billing sur navigateur : les deux mêmes
              // offres (mêmes tarifs que l'app) passent par Stripe Checkout
              // à la place — voir `_buyWeb`. Prix affichés en dur (pas de
              // catalogue dynamique comme `ProductDetails` côté Play
              // Billing) : à garder synchronisés avec les prix Stripe
              // configurés côté Cloud Functions.
              if (_webError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_webError!, style: TextStyle(fontSize: 13, color: AppColors.alert)),
                ),
              Card(
                child: ListTile(
                  title: const Text('Abonnement Illimité (Didou-immo)'),
                  subtitle: const Text('Sans engagement, résiliable à tout moment'),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('5,99 €', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('/mois', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  enabled: !_purchasing,
                  onTap: () => _buyWeb('monthly'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Abonnement Illimité (Didou-immo)'),
                  subtitle: const Text('Sans engagement, résiliable à tout moment'),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('41,99 €', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('/an', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  enabled: !_purchasing,
                  onTap: () => _buyWeb('yearly'),
                ),
              ),
              if (_purchasing)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ] else ...[
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (!_loading && _products.isEmpty)
                Text("Aucune offre disponible pour le moment.", style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              if (!_loading)
                ..._products.map((p) {
                  final period = _billingPeriodSuffix(p);
                  return Card(
                    child: ListTile(
                      title: Text(p.title),
                      subtitle: Text(p.description),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(p.price, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (period != null)
                            // AppColors.textMuted (et non Colors.black54, fixe) :
                            // en thème sombre, un gris "noir 54%" est quasiment
                            // invisible sur fond sombre — signalé par
                            // l'utilisateur, le "/mois"/"/an" ajouté juste avant
                            // était bien affiché mais illisible.
                            Text(period, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                      enabled: !_purchasing,
                      onTap: () {
                        setState(() => _purchasing = true);
                        _billing.buySubscription(p);
                      },
                    ),
                  );
                }),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _billing.restorePurchases(),
                child: const Text('Restaurer mes achats'),
              ),
            ],
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CgvScreen())),
              child: const Text('Voir les conditions générales de vente'),
            ),
          ],
        ),
      ),
    );
  }
}
