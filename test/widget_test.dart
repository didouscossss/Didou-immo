// Test de fumée : l'app démarre et chaque onglet se construit sans erreur.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:didou_immo/main.dart';

/// Scrolle le `ListView` de l'onglet courant jusqu'à ce que [finder] soit
/// construit et visible (les onglets sont de longues listes non paresseuses,
/// mais les éléments hors du viewport + cacheExtent ne sont pas inflatés).
Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pump();
  }
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  testWidgets('Les 5 onglets se construisent sans erreur, en novice et en avancé',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding-done': true});

    await tester.pumpWidget(const DidouImmoApp());
    await tester.pumpAndSettle();

    expect(find.text('Rendement'), findsOneWidget);
    expect(find.text('Le bien'), findsOneWidget);
    expect(tester.takeException(), isNull);

    const tabs = ['Marché', 'Fiscalité', 'Projection', 'Comparer', 'Bien'];
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

  testWidgets('Basculer en courte durée, enregistrer deux biens, comparer',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding-done': true});

    await tester.pumpWidget(const DidouImmoApp());
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
  });
}
