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

/// Scrolle la `ListView` de l'onglet courant jusqu'en bas, sans viser un
/// widget précis — utile pour vérifier qu'un bloc masqué/réordonné a bien
/// disparu (ou est bien de retour) plutôt que simplement hors du viewport.
Future<void> _scrollTabListToBottom(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Symétrique de [_scrollTabListToBottom] — `_scrollToAndTap` ne scrolle
/// que vers le bas, donc remonter en haut d'abord est nécessaire pour
/// retrouver un widget situé tôt dans la liste après l'avoir descendue.
Future<void> _scrollTabListToTop(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, 400));
    await tester.pump();
  }
  await tester.pumpAndSettle();
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

    // Retour sur "Bien" : la localisation/le prix/la surface/le type du
    // bien 1 sont maintenant verrouillés — "+ Nouveau bien" repart d'un
    // formulaire vierge pour en créer un second, distinct, en courte durée.
    await tester.tap(find.text('Bien'));
    await tester.pumpAndSettle();
    await _scrollToAndTap(tester, find.text('+ Nouveau bien'));
    await tester.pumpAndSettle();
    await _scrollToAndTap(tester, find.text('Courte durée'));
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

  testWidgets('Personnaliser mon affichage : masquer un onglet le retire de la barre, réinitialiser le ramène',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding-done': true});

    await tester.pumpWidget(const DidouImmoApp(firebaseReady: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.dashboard_customize_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Personnaliser mon affichage'), findsOneWidget);

    // Masque "Carte" : son interrupteur passe à faux, et il disparaît de la
    // barre du bas une fois revenu sur l'écran principal.
    final carteRow = find.ancestor(of: find.text('Carte'), matching: find.byType(ListTile));
    await tester.tap(find.descendant(of: carteRow, matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // `tester.pageBack()` cherche le bouton retour par son tooltip "Back" —
    // en français ("Retour"), il ne le trouve pas ; on tape directement le
    // `BackButton` que l'AppBar génère automatiquement.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Carte'), findsNothing);
    expect(tester.takeException(), isNull);

    // Réinitialiser ramène les 7 onglets dans leur ordre/visibilité d'origine.
    await tester.tap(find.byIcon(Icons.dashboard_customize_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réinitialiser'));
    await tester.pumpAndSettle();
    // `tester.pageBack()` cherche le bouton retour par son tooltip "Back" —
    // en français ("Retour"), il ne le trouve pas ; on tape directement le
    // `BackButton` que l'AppBar génère automatiquement.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Carte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Personnaliser "Bien" : masquer une section la retire de l\'onglet, réinitialiser la ramène',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding-done': true});

    await tester.pumpWidget(const DidouImmoApp(firebaseReady: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.dashboard_customize_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Personnaliser mon affichage'), findsOneWidget);

    final bienRow = find.ancestor(of: find.text('Bien'), matching: find.byType(ListTile));
    await tester.tap(bienRow);
    await tester.pumpAndSettle();
    expect(find.text('Personnaliser "Bien"'), findsOneWidget);

    // Masque "Export PDF" : le bloc disparaît de l'onglet une fois revenu dessus.
    // La liste des 10 blocs dépasse le viewport — il faut la faire défiler
    // pour que le dernier ("Export PDF") soit construit et visible.
    await tester.dragUntilVisible(find.text('Export PDF'), find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    final exportRow = find.ancestor(of: find.text('Export PDF'), matching: find.byType(ListTile));
    await tester.tap(find.descendant(of: exportRow, matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    // Le bloc "Exporter en PDF" est tout en bas de l'onglet "Bien" — sans
    // le scroller jusque là, son absence ne prouverait rien (il pourrait
    // simplement être hors du viewport, comme le reste de la liste).
    await _scrollTabListToBottom(tester);
    expect(find.text('Exporter en PDF'), findsNothing);
    expect(tester.takeException(), isNull);

    // Réinitialiser ramène les 10 blocs dans leur ordre/visibilité d'origine.
    await tester.tap(find.byIcon(Icons.dashboard_customize_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.ancestor(of: find.text('Bien'), matching: find.byType(ListTile)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réinitialiser'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await _scrollTabListToBottom(tester);
    expect(find.text('Exporter en PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Personnaliser "Fiscalité" : masquer une section la retire de l\'onglet, réinitialiser la ramène',
      (WidgetTester tester) async {
    // Vérifie que le mécanisme générique (voir `kTabSections`) fonctionne
    // aussi pour un onglet autre que "Bien", le premier à l'avoir reçu.
    SharedPreferences.setMockInitialValues({'onboarding-done': true});

    await tester.pumpWidget(const DidouImmoApp(firebaseReady: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.dashboard_customize_outlined));
    await tester.pumpAndSettle();
    final fiscRow = find.ancestor(of: find.text('Fiscalité'), matching: find.byType(ListTile));
    await tester.tap(fiscRow);
    await tester.pumpAndSettle();
    expect(find.text('Personnaliser "Fiscalité"'), findsOneWidget);

    await tester.dragUntilVisible(find.text('Structure de détention'), find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    final structureRow = find.ancestor(of: find.text('Structure de détention'), matching: find.byType(ListTile));
    await tester.tap(find.descendant(of: structureRow, matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fiscalité'));
    await tester.pumpAndSettle();
    await _scrollTabListToBottom(tester);
    expect(find.text('Structure de détention'), findsNothing);
    expect(tester.takeException(), isNull);

    // Réinitialiser ramène les 4 blocs dans leur ordre/visibilité d'origine.
    await tester.tap(find.byIcon(Icons.dashboard_customize_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.ancestor(of: find.text('Fiscalité'), matching: find.byType(ListTile)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réinitialiser'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fiscalité'));
    await tester.pumpAndSettle();
    await _scrollTabListToBottom(tester);
    expect(find.text('Structure de détention'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("L'export PDF exige un bien enregistré, et un calcul non enregistré prévient avant d'être perdu",
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding-done': true});

    await tester.pumpWidget(const DidouImmoApp(firebaseReady: false));
    await tester.pumpAndSettle();

    // Avant tout enregistrement, le bouton d'export PDF reste désactivé
    // (calcul en cours, pas encore un bien enregistré) et aucune
    // modification "non enregistrée" n'est signalée (rien n'a encore été
    // saisi).
    await _scrollTabListToBottom(tester);
    OutlinedButton pdfButton() => tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Générer le PDF'));
    expect(pdfButton().onPressed, isNull);
    expect(find.text('Modifications non enregistrées'), findsNothing);

    // Enregistrer le bien débloque l'export PDF.
    await _scrollToAndTap(tester, find.text('Enregistrer ce bien'));
    await tester.pumpAndSettle();
    expect(find.text('Comparatif'), findsOneWidget); // navigué vers "Comparer"

    // Retour sur "Bien" : le PDF reste disponible tant que rien n'a changé.
    await tester.tap(find.text('Bien'));
    await tester.pumpAndSettle();
    await _scrollTabListToBottom(tester);
    expect(pdfButton().onPressed, isNotNull);

    // Modifier un champ invalide l'export PDF et affiche l'indicateur de
    // modifications non enregistrées.
    await _scrollTabListToTop(tester);
    await _scrollToAndTap(tester, find.text('Meublé'));
    await tester.pumpAndSettle();
    await _scrollTabListToBottom(tester);
    expect(find.text('Modifications non enregistrées'), findsOneWidget);
    expect(pdfButton().onPressed, isNull);

    // Ouvrir un autre bien depuis "Comparer" prévient d'abord qu'on va
    // perdre ce calcul non enregistré.
    await tester.tap(find.text('Comparer'));
    await tester.pumpAndSettle();
    await _scrollToAndTap(tester, find.text('Bien sans nom'));
    await tester.pumpAndSettle();
    expect(find.text('Calcul non enregistré'), findsOneWidget);

    // "Annuler" ne perd rien : toujours sur "Comparer", pas de navigation.
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Calcul non enregistré'), findsNothing);
    expect(find.text('Comparatif'), findsOneWidget);

    // "Continuer sans enregistrer" recharge le bien : retour sur "Bien"
    // avec le calcul d'origine (non modifié), le PDF redevient disponible.
    await _scrollToAndTap(tester, find.text('Bien sans nom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer sans enregistrer'));
    await tester.pumpAndSettle();
    await _scrollTabListToBottom(tester);
    expect(find.text('Modifications non enregistrées'), findsNothing);
    expect(pdfButton().onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      "La rentabilité reste verrouillée tant que le bien n'est pas enregistré ; la localisation, le prix, la surface et le type se verrouillent une fois enregistré",
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding-done': true});

    await tester.pumpWidget(const DidouImmoApp(firebaseReady: false));
    await tester.pumpAndSettle();

    // Avant tout enregistrement : la rentabilité reste verrouillée, pas de
    // bandeau "+ Nouveau bien" (rien à réinitialiser sur un bien vierge).
    await tester.dragUntilVisible(find.text('Rentabilité verrouillée'), find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(find.text('RENTABILITÉ NETTE'), findsNothing);
    expect(find.text('+ Nouveau bien'), findsNothing);

    // Enregistrer débloque la rentabilité et verrouille l'identité du bien.
    await _scrollToAndTap(tester, find.text('Enregistrer ce bien'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bien'));
    await tester.pumpAndSettle();
    expect(find.text('+ Nouveau bien'), findsOneWidget);
    await tester.dragUntilVisible(find.text('RENTABILITÉ NETTE'), find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(find.text('Rentabilité verrouillée'), findsNothing);
    expect(tester.takeException(), isNull);

    // "+ Nouveau bien" repart d'un formulaire vierge : la rentabilité se
    // reverrouille, le bandeau disparaît.
    await _scrollTabListToTop(tester);
    await _scrollToAndTap(tester, find.text('+ Nouveau bien'));
    await tester.pumpAndSettle();
    expect(find.text('+ Nouveau bien'), findsNothing);
    await tester.dragUntilVisible(find.text('Rentabilité verrouillée'), find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
