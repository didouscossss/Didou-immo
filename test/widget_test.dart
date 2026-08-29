// Test de fumée : l'app démarre et chaque onglet se construit sans erreur.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:didou_immo/main.dart';
import 'package:didou_immo/screens/rendement/onboarding_sheet.dart';

/// Scrolle le `ListView` de l'onglet courant jusqu'à ce que [finder] soit
/// construit et visible (les onglets sont de longues listes non paresseuses,
/// mais les éléments hors du viewport + cacheExtent ne sont pas inflatés).
Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pump();
  }
  await tester.pumpAndSettle();
  // Le widget peut exister dans l'arbre sans être entièrement visible (donc
  // pas fiablement "hit-testable") — `ensureVisible` scrolle le strict
  // nécessaire pour l'amener dans le viewport avant de taper dessus.
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  testWidgets('Les 6 onglets se construisent sans erreur, en novice et en avancé',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding-done': true});

    await tester.pumpWidget(const DidouImmoApp(firebaseReady: false));
    await tester.pumpAndSettle();

    expect(find.text('Rendement'), findsOneWidget);
    expect(find.text('Le bien'), findsOneWidget);
    expect(tester.takeException(), isNull);

    const tabs = ['Marché', 'Fiscalité', 'Projection', 'Comparer', 'Patrimoine', 'Bien'];
    for (final label in tabs) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'onglet "$label" (novice)');
    }

    // Bascule en mode avancé et revérifie chaque onglet (affiche des blocs
    // supplémentaires : offres de prêt, détail des régimes, structures...).
    await tester.tap(find.text('Avancé'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (final label in tabs) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'onglet "$label" (avancé)');
    }
  });

  testWidgets('L\'onglet Carte se construit sans erreur', (WidgetTester tester) async {
    // Séparé du test ci-dessus : la carte charge des tuiles réseau
    // (OpenStreetMap), donc on évite `pumpAndSettle` (qui attendrait le
    // règlement complet des requêtes réseau) et on se contente de vérifier
    // que le premier rendu ne lève aucune exception synchrone.
    SharedPreferences.setMockInitialValues({'onboarding-done': true});

    await tester.pumpWidget(const DidouImmoApp(firebaseReady: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Carte'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Basculer en courte durée, enregistrer deux biens, comparer',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding-done': true});

    await tester.pumpWidget(const DidouImmoApp(firebaseReady: false));
    await tester.pumpAndSettle();

    // Bien 1 (longue durée, par défaut) — enregistré tel quel. Le bouton est
    // en bas d'une longue liste : on scrolle jusqu'à ce qu'il soit construit.
    await _scrollToAndTap(tester, find.text('Enregistrer ce bien'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Comparatif'), findsOneWidget);

    // Retour sur "Bien", bascule en courte durée, enregistre un 2e bien.
    await tester.tap(find.text('Bien'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Courte durée'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _scrollToAndTap(tester, find.text('Enregistrer ce bien'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Mode avancé : les barres de comparatif (2 biens) doivent s'afficher.
    await tester.tap(find.text('Avancé'));
    await tester.pumpAndSettle();
    expect(find.text('Rentabilité nette (%)'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Marque le premier bien "acquis" (date du jour) : fait apparaître une
    // carte dans l'onglet Patrimoine, jusque-là vide.
    await tester.tap(find.text('À l\'étude').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Patrimoine'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Ajouter un relevé'), findsNothing); // carte repliée par défaut

    // Déplie la carte, puis ajoute deux relevés — de quoi exercer le
    // graphique (affiché à partir de 2 relevés), pas seulement la liste vide.
    await _scrollToAndTap(tester, find.text('Bien sans nom'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter un relevé'), findsOneWidget);

    for (final loyer in ['750', '780']) {
      await _scrollToAndTap(tester, find.text('Ajouter un relevé'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Loyer réellement perçu'), loyer);
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.textContaining('Relevés'), findsOneWidget);
  });

  testWidgets("L'onboarding affiche Didou et se parcourt sans erreur",
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({}); // pas de 'onboarding-done' -> affiché

    await tester.pumpWidget(const DidouImmoApp(firebaseReady: false));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue 👋'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage &&
        (w.image as AssetImage).assetName == 'assets/images/didou_face.png'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final onboarding = find.byType(OnboardingSheet);
    await tester.tap(find.descendant(of: onboarding, matching: find.text('Courte durée')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Ton budget'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text("C'est parti"));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue 👋'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
