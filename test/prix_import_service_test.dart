import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:didou_immo/services/prix_import_service.dart';

/// En-tête réel du fichier "Statistiques totales DVF" (data.gouv.fr),
/// confirmé sur un fichier téléchargé — une seule ligne par commune,
/// prix agrégé sur 5 ans, pas de colonne année.
const _header = 'code_geo;libelle_geo;code_parent;echelle_geo;'
    'nb_ventes_whole_appartement;moy_prix_m2_whole_appartement;med_prix_m2_whole_appartement;'
    'nb_ventes_whole_maison;moy_prix_m2_whole_maison;med_prix_m2_whole_maison;'
    'nb_ventes_whole_apt_maison;moy_prix_m2_whole_apt_maison;med_prix_m2_whole_apt_maison;'
    'nb_ventes_whole_local;moy_prix_m2_whole_local;med_prix_m2_whole_local';

/// Une ligne "commune" avec des valeurs plausibles sur toutes les colonnes
/// (appartement/maison/apt_maison/local) — seule la colonne "apt_maison"
/// doit être retenue par le parseur.
String _ligneCommune(String insee, {required int nbVentes, required double prixMedian, String echelle = 'commune', String? nom}) {
  // Les colonnes appartement/maison/local portent des valeurs différentes
  // de "apt_maison" pour vérifier qu'on ne les confond pas.
  return '$insee;${nom ?? 'Commune $insee'};75;$echelle;'
      '5;1000;1100;' // appartement
      '5;1200;1300;' // maison
      '$nbVentes;${prixMedian - 50};$prixMedian;' // apt_maison — la bonne colonne
      '2;2000;2100'; // local
}

String _buildCsv({int nbCommunesBase = 1005, List<String> extraLines = const []}) {
  // `extraLines` en tête (pas en queue) : l'échantillon renvoyé par
  // `parseCsv` ne retient que les toutes premières lignes valides du
  // fichier, donc un cas particulier ajouté en fin de liste n'y apparaîtrait
  // jamais.
  final lignes = <String>[_header, ...extraLines];
  for (var i = 0; i < nbCommunesBase; i++) {
    lignes.add(_ligneCommune(i.toString().padLeft(5, '0'), nbVentes: 10, prixMedian: (2000 + i).toDouble()));
  }
  return lignes.join('\n');
}

void main() {
  group('PrixImportService.parseCsv', () {
    test('reconnaît les communes et publie le prix médian de la colonne "apt_maison"', () {
      final data = PrixImportService.parseCsv(utf8.encode(_buildCsv())).data;
      expect(data.length, 1005);
      final commune0 = data['00000'] as Map;
      expect(commune0['p'], 2000);
      expect(commune0['n'], 10);
    });

    test("l'échantillon renvoyé donne le nom, le code et le prix — pour vérifier à l'œil dans l'admin", () {
      final csv = _buildCsv(extraLines: [
        _ligneCommune('86194', nbVentes: 400, prixMedian: 2100, nom: 'Poitiers'),
      ]);
      final sample = PrixImportService.parseCsv(utf8.encode(csv)).sample;
      expect(sample.any((s) => s.contains('Poitiers') && s.contains('86194') && s.contains('2100')), isTrue);
    });

    test('ignore les lignes hors "commune" quand une colonne échelle_geo existe', () {
      final csv = _buildCsv(extraLines: [
        _ligneCommune('88888', nbVentes: 500, prixMedian: 3000, echelle: 'departement'),
      ]);
      final data = PrixImportService.parseCsv(utf8.encode(csv)).data;
      expect(data.containsKey('88888'), isFalse);
    });

    test('se rabat sur le prix moyen si la colonne prix médian est absente', () {
      final header = 'code_geo;echelle_geo;nb_ventes_whole_apt_maison;moy_prix_m2_whole_apt_maison';
      final lignes = <String>[header];
      for (var i = 0; i < 1005; i++) {
        lignes.add('${i.toString().padLeft(5, '0')};commune;10;${2000 + i}');
      }
      final data = PrixImportService.parseCsv(utf8.encode(lignes.join('\n'))).data;
      expect(data.length, 1005);
      expect((data['00000'] as Map)['p'], 2000);
    });

    test('accepte des en-têtes avec majuscules/accents/espaces équivalents', () {
      final lignes = <String>['Code Geo;Échelle Géo;Nb Ventes Whole Apt Maison;Med Prix M2 Whole Apt Maison'];
      for (var i = 0; i < 1005; i++) {
        lignes.add('${i.toString().padLeft(5, '0')};commune;10;${2000 + i}');
      }
      final data = PrixImportService.parseCsv(utf8.encode(lignes.join('\n'))).data;
      expect(data.length, 1005);
    });

    test('ignore une ligne avec un nombre de ventes ou un prix non numérique (donnée masquée "s")', () {
      final csv = _buildCsv(extraLines: [
        '66666;Commune 66666;75;commune;5;1000;1100;5;1200;1300;s;s;s;2;2000;2100',
      ]);
      final data = PrixImportService.parseCsv(utf8.encode(csv)).data;
      expect(data.containsKey('66666'), isFalse);
    });

    test('lève une exception explicite listant les vraies colonnes si les colonnes attendues sont introuvables', () {
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
    test('renvoie le nombre de communes reconnues', () {
      final data = PrixImportService.parseCsv(utf8.encode(_buildCsv(nbCommunesBase: 1200))).data;
      final summary = PrixImportService.summarize(data);
      expect(summary.nbCommunes, 1200);
    });
  });
}
