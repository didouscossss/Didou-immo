// File generated manually from the Firebase Console config for the
// "didou-immo" project (Web + Android apps) — written by hand because the
// FlutterFire CLI could not authenticate from this session (see README,
// "Ce qu'il reste à faire" → étape 1). Regenerate with
// `flutterfire configure` from a machine with normal network access if you
// ever need to add another platform (iOS, macOS...).
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Options Firebase par plateforme. Utilisé via
/// `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
/// dans `main.dart`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions n\'a été configuré que pour le web et '
          'Android (${defaultTargetPlatform.name} non pris en charge). '
          'Relance `flutterfire configure` pour ajouter une autre '
          'plateforme.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCYMrdKMUeQFxaXJ0I8L6JRG9b4OqReYnI',
    appId: '1:561302404630:web:b6cae02a8f0b4556847f37',
    messagingSenderId: '561302404630',
    projectId: 'didou-immo',
    authDomain: 'didou-immo.firebaseapp.com',
    storageBucket: 'didou-immo.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC0LWds3_zASGtVa8jW4morBviYphRuHvM',
    appId: '1:561302404630:android:2e61d83d0e5f02cb847f37',
    messagingSenderId: '561302404630',
    projectId: 'didou-immo',
    storageBucket: 'didou-immo.firebasestorage.app',
  );
}
