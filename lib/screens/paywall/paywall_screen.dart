import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../../services/billing_service.dart';
import '../../services/firestore_service.dart';
import '../../state/user_account_state.dart';

/// Affiché quand l'utilisateur a épuisé ses biens gratuits et n'est pas
/// encore abonné. Propose les deux offres (mensuelle / annuelle).
///
/// Google Play Billing n'a pas d'implémentation web : sur le web, cet
/// écran l'indique clairement plutôt que d'appeler une API absente.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _billing = BillingService();
  final _firestore = FirestoreService();
  List<ProductDetails> _products = [];
  bool _loading = true;
  bool _purchasing = false;

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
    final uid = account.user?.uid;
    if (uid != null) {
      await _firestore.setSubscribed(uid, true);
      await account.refresh();
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
            if (kIsWeb)
              const Text(
                "L'abonnement se souscrit depuis l'application Android (Google Play Billing) — "
                "pas disponible sur cette version web.",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              )
            else ...[
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (!_loading && _products.isEmpty)
                const Text("Aucune offre disponible pour le moment.", style: TextStyle(fontSize: 13, color: Colors.black54)),
              if (!_loading)
                ..._products.map(
                  (p) => Card(
                    child: ListTile(
                      title: Text(p.title),
                      subtitle: Text(p.description),
                      trailing: Text(p.price, style: const TextStyle(fontWeight: FontWeight.bold)),
                      enabled: !_purchasing,
                      onTap: () {
                        setState(() => _purchasing = true);
                        _billing.buySubscription(p);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _billing.restorePurchases(),
                child: const Text('Restaurer mes achats'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
