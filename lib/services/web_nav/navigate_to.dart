/// Redirige le navigateur vers une URL (ex. page de paiement Stripe
/// Checkout, voir `paywall_screen.dart`) — implémentation web seulement
/// (`navigate_to_web.dart`) ; `navigate_to_stub.dart` ne fait rien ailleurs,
/// cet appel n'étant de toute façon jamais déclenché hors web (toujours
/// gardé par `kIsWeb` côté appelant).
library;

export 'navigate_to_stub.dart' if (dart.library.js_interop) 'navigate_to_web.dart';
