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
  });
}
