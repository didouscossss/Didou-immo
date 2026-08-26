import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Intègre Google Play Billing pour l'abonnement.
///
/// ÉTAPES CÔTÉ PLAY CONSOLE (à faire avant que ce code fonctionne) :
/// 1. Créer un produit d'abonnement dans Play Console > Monétisation > Produits > Abonnements
/// 2. Créer deux offres de base sur ce produit : mensuelle (4,99€) et annuelle (50€)
/// 3. Utiliser les IDs exacts définis ci-dessous (subscriptionProductId) — ils doivent
///    correspondre EXACTEMENT à ceux configurés dans Play Console
/// 4. L'app doit être publiée au moins en test interne pour que les achats fonctionnent
///
/// Le statut d'abonnement vérifié doit être écrit dans Firestore (isSubscribed,
/// subscriptionExpiry) via une Cloud Function qui valide le reçu d'achat côté
/// serveur (Real-time Developer Notifications) — ne jamais faire confiance
/// uniquement au statut local de l'app pour débloquer les fonctionnalités payantes.
class BillingService {
  static const String subscriptionProductId = 'rendement_abonnement';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetailsResponse> loadProducts() {
    return _iap.queryProductDetails({subscriptionProductId});
  }

  void listenToPurchaseUpdates({
    required void Function(PurchaseDetails purchase) onPurchase,
    required void Function(Object error) onError,
  }) {
    _subscription = _iap.purchaseStream.listen(
      (purchases) {
        for (final p in purchases) {
          if (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored) {
            onPurchase(p);
            // IMPORTANT : compléter l'achat, sinon Google Play le rembourse
            // automatiquement après quelques jours.
            if (p.pendingCompletePurchase) {
              _iap.completePurchase(p);
            }
          }
        }
      },
      onError: onError,
    );
  }

  Future<void> buySubscription(ProductDetails product) {
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  void dispose() => _subscription?.cancel();
}
