import 'package:flutter_test/flutter_test.dart';
import 'package:didou_immo/utils/calculations.dart';

void main() {
  group('computeTri', () {
    // Achat 100% cash, aucun cash-flow en cours de route, valeur inchangée
    // à la revente : l'argent ressort exactement comme il est entré, donc
    // le TRI attendu est 0 %, quelle que soit la durée.
    const form = PropertyInput(
      mode: RentalMode.longue,
      surface: 50,
      prix: 100000,
      notaire: 0,
      travaux: 0,
      notaireAuto: false,
      travauxAuto: false,
      taxeFonciere: 0,
      assurance: 0,
      apport: 100000,
      tauxPct: 0,
      dureePretAns: 20,
      croissanceValeur: 0,
      fraisAgenceRevente: 0,
      dureeProjection: 5,
    );

    test('TRI nul quand le capital ressort exactement comme il est entré', () {
      final core = computeCore(form);
      expect(core.montantEmprunte, 0);
      expect(core.cashflowMensuel, 0);
      final tri = computeTri(form, core);
      expect(tri.tauxPct, isNotNull);
      expect(tri.tauxPct!, closeTo(0, 0.5));
    });

    test('TRI non calculable sans apport réel', () {
      final noApport = form.copyWith(apport: 0);
      final core = computeCore(noApport);
      final tri = computeTri(noApport, core);
      expect(tri.tauxPct, isNull);
    });

    test('TRI positif quand la revente dégage une plus-value nette', () {
      final plusValue = form.copyWith(croissanceValeur: 5);
      final core = computeCore(plusValue);
      final tri = computeTri(plusValue, core);
      expect(tri.tauxPct, isNotNull);
      expect(tri.tauxPct!, greaterThan(0));
    });

    test('TRI négatif quand les frais d\'agence à la revente dépassent la croissance (bug corrigé)', () {
      // Valeur du bien inchangée (croissanceValeur: 0, comme le cas "TRI
      // nul" ci-dessus) mais 10 % de frais d'agence à la revente : le prix
      // net d'agence (90 000 €) ressort SOUS le prix d'acquisition
      // (100 000 €), donc aucune plus-value (`plusValueBrute` plafonnée à
      // 0) — le bug recalculait alors le produit de la revente à partir du
      // prix d'ACQUISITION plutôt que du prix de VENTE net réellement
      // perçu, masquant entièrement cette perte de 10 000 € (TRI à 0 %
      // au lieu d'un TRI négatif).
      final perte = form.copyWith(fraisAgenceRevente: 10);
      final core = computeCore(perte);
      final tri = computeTri(perte, core);
      expect(tri.tauxPct, isNotNull);
      expect(tri.tauxPct!, lessThan(0));
    });
  });

  group('computeCityInvestScore', () {
    const ville = CityRef('Testville', 3000, 12, false, 0, 0);

    test('un repli des prix ne doit jamais scorer aussi bien qu\'une hausse modérée (bug corrigé)', () {
      // Avant correction, la branche "évolution <= 10 %" attrapait aussi
      // toutes les valeurs négatives avant d'atteindre les branches
      // dédiées au repli — un marché en net recul (-20 %) notait alors
      // aussi bien qu'une hausse saine de +7 %.
      final declin = computeCityInvestScore(ville, evolution1AnPct: -20);
      final hausseModeree = computeCityInvestScore(ville, evolution1AnPct: 7);
      expect(declin.score, lessThan(hausseModeree.score));
    });
  });

  group('computeScore', () {
    test('la pondération personnalisée du cash-flow dégrade le score dans la même proportion, pas d\'un écart absolu fixe', () {
      // Cash-flow mensuel de -100 € : avec le poids par défaut (25), le
      // composant retombe à 12,5 (moitié du maximum). Avant correction,
      // doubler le poids ajoutait le même écart ABSOLU (-12,5 pt) au lieu
      // de rester à la même proportion (moitié du nouveau maximum).
      const form = PropertyInput(
        mode: RentalMode.longue,
        surface: 50,
        prix: 100000,
        notaire: 0,
        travaux: 0,
        notaireAuto: false,
        travauxAuto: false,
        taxeFonciere: 1200,
        assurance: 0,
        apport: 100000,
        tauxPct: 0,
        dureePretAns: 20,
      );
      final core = computeCore(form);
      expect(core.cashflowMensuel, closeTo(-100, 0.01));

      final defaut = computeScore(form, core, null);
      final poidsDouble = computeScore(form, core, null,
          weights: const ScoreWeights(rendement: 40, cashflow: 50, marche: 20, occupation: 15));

      expect(defaut.parts.cashflow, closeTo(12.5, 0.01));
      expect(poidsDouble.parts.cashflow, closeTo(25, 0.01));
    });
  });

  group('SuiviEntry.nbMois', () {
    test('une période de 3 mois pleins compte ~3 mois, pas 1', () {
      final entry = SuiviEntry(
        id: 'test-1',
        dateDebut: DateTime(2026, 1, 1),
        dateFin: DateTime(2026, 3, 31),
        loyerPercu: 750,
      );
      expect(entry.nbMois, closeTo(3, 0.1));
      // Le loyer perçu cumulé sur la période doit donc être ~3x le loyer
      // mensuel, pas le loyer mensuel une seule fois (le bug signalé).
      expect(entry.loyerPercu! * entry.nbMois, closeTo(2250, 80));
    });

    test('une période ouverte (sans dateFin) court jusqu\'à aujourd\'hui', () {
      final debut = DateTime.now().subtract(const Duration(days: 60));
      final entry = SuiviEntry(id: 'test-2', dateDebut: debut, loyerPercu: 500);
      expect(entry.nbMois, closeTo(2, 0.2));
    });
  });
}
