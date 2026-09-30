import 'package:web/web.dart' as web;

/// Redirige la page courante — utilisé pour envoyer le navigateur vers la
/// page de paiement Stripe Checkout (voir `paywall_screen.dart`).
void navigateTo(String url) {
  web.window.location.href = url;
}
