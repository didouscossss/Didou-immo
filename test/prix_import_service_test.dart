import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:didou_immo/services/prix_import_service.dart';

/// Construit un CSV synthétique de N communes (une ligne "2025" chacune,
/// prix croissant pour les distinguer), plus quelques cas particuliers
/// utilisés par les tests individuels ci-dessous.
String _buildCsv({int nbCommunesBase = 1005, List<String> extraLines = const []}) {
  final header = 'code_geo;echelle_geo;annee;nb_ventes;prix_m2_median';
  final lignes = <String>[header];
  for (var i = 0; i < nbCommunesBase; i++) {
    final insee = i.toString().padLeft(5, '0');
    lignes.add('$insee;commune;2025;10;${2000 + i}');
  }
  lignes.addAll(extraLines);
  return lignes.join('\n');
}

void main() {
  group('PrixImportService.parseCsv', () {
    test('reconnaît les communes et publie le prix médian', () {
      final csv = _buildCsv();
      final data = PrixImportService.parseCsv(utf8.encode(csv));
      expect(data.length, 1005);
      final commune0 = data['00000'] as Map;
      expect(commune0['p'], 2000);
      expect(commune0['n'], 10);
      expect(commune0['a'], 2025);
      expect(commune0.containsKey('e'), isFalse); // pas d'année précédente dans le fichier
    });

    test("calcule l'évolution sur 1 an quand l'année précédente est présente", () {
      final csv = _buildCsv(extraLines: ['99999;commune;2024;8;2000', '99999;commune;2025;8;2200']);
      final data = PrixImportService.parseCsv(utf8.encode(csv));
      final commune = data['99999'] as Map;
      expect(commune['a'], 2025);
      expect(commune['p'], 2200);
      expect(commune['e'], 10.0); // +200/2000 = +10%
    });

    test('ignore les lignes hors "commune" quand une colonne échelle_geo existe', () {
      final csv = _buildCsv(extraLines: ['88888;departement;2025;500;3000']);
      final data = PrixImportService.parseCsv(utf8.encode(csv));
      expect(data.containsKey('88888'), isFalse);
    });

    test('pondère par le nombre de ventes quand plusieurs lignes existent pour la même année', () {
      final csv = _buildCsv(extraLines: [
        '77777;commune;2025;10;2000', // 10 ventes à 2000
        '77777;commune;2025;30;3000', // 30 ventes à 3000
      ]);
      final data = PrixImportService.parseCsv(utf8.encode(csv));
      final commune = data['77777'] as Map;
      // Moyenne pondérée : (10*2000 + 30*3000) / 40 = 2750
      expect(commune['p'], 2750);
      expect(commune['n'], 40);
    });

    test('se rabat sur le prix moyen si la colonne prix médian est absente', () {
      final header = 'code_geo;echelle_geo;annee;nb_ventes;prix_m2_moyen';
      final lignes = <String>[header];
      for (var i = 0; i < 1005; i++) {
        lignes.add('${i.toString().padLeft(5, '0')};commune;2025;10;${2000 + i}');
      }
      final data = PrixImportService.parseCsv(utf8.encode(lignes.join('\n')));
      expect(data.length, 1005);
      expect((data['00000'] as Map)['p'], 2000);
    });

    test('accepte des en-têtes avec majuscules/accents/espaces équivalents', () {
      final lignes = <String>['Code INSEE;Échelle Géo;Année;Nb Ventes;Prix M2 Médian'];
      for (var i = 0; i < 1005; i++) {
        lignes.add('${i.toString().padLeft(5, '0')};commune;2025;10;${2000 + i}');
      }
      final data = PrixImportService.parseCsv(utf8.encode(lignes.join('\n')));
      expect(data.length, 1005);
    });

    test('lève une exception explicite si les colonnes attendues sont introuvables', () {
      final csv = 'foo;bar;baz\n1;2;3';
      expect(
        () => PrixImportService.parseCsv(utf8.encode(csv)),
        throwsA(isA<PrixImportException>().having((e) => e.message, 'message', contains('foo, bar, baz'))),
      );
    });

    test('lève une exception si trop peu de communes sont reconnues', () {
      final csv = _buildCsv(nbCommunesBase: 10);
      expect(() => PrixImportService.parseCsv(utf8.encode(csv)), throwsA(isA<PrixImportException>()));
    });
  });

  group('PrixImportService.summarize', () {
    test('renvoie le nombre de communes et l\'année la plus récente', () {
      final data = PrixImportService.parseCsv(utf8.encode(_buildCsv(nbCommunesBase: 1200)));
      final summary = PrixImportService.summarize(data);
      expect(summary.nbCommunes, 1200);
      expect(summary.anneeMax, 2025);
    });
  });
}
