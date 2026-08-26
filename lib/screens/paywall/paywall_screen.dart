import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../services/billing_service.dart';

/// Affiché quand l'utilisateur a épuisé ses 3 biens gratuits et n'est pas
/// encore abonné. Propose les deux offres (mensuelle / annuelle).
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _billing = BillingService();
  List<ProductDetails> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await _billing.isAvailable();
    if (!available) {
      setState(() => _loading = false);
      return;
    }
    final response = await _billing.loadProducts();
    setState(() {
      _products = response.productDetails;
      _loading = false;
    });
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
            const Text(
              "Tu as utilisé tes 3 biens gratuits. Passe en illimité pour "
              "continuer à enregistrer et comparer autant de biens que tu veux.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading)
              ..._products.map(
                (p) => Card(
                  child: ListTile(
                    title: Text(p.title),
                    subtitle: Text(p.description),
                    trailing: Text(p.price,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => _billing.buySubscription(p),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _billing.restorePurchases(),
              child: const Text('Restaurer mes achats'),
            ),
          ],
        ),
      ),
    );
  }
}
