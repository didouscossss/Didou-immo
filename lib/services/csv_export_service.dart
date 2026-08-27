import 'dart:convert';
import 'dart:typed_data';

import '../models/saved_property.dart';
import '../utils/calculations.dart';
import 'file_saver/save_bytes.dart';

/// Export CSV de tous les biens enregistrés (onglet Comparer) — une ligne
/// par bien, pour croiser ou retravailler les chiffres soi-même dans un
/// tableur, en complément du PDF (qui détaille un seul bien à la fois).
///
/// Séparateur `;` (le `,` est réservé aux nombres à virgule dans un tableur
/// en locale française) et nombres au format international (point décimal,
/// sans séparateur de milliers) — le format le plus largement reconnu comme
/// numérique sans ambiguïté par les tableurs, quelle que soit leur locale.
class CsvExportService {
  static const _headers = [
    'Nom',
    'Commune',
    'Mode',
    'Prix (EUR)',
    'Surface (m2)',
    'Prix/m2 (EUR)',
    'Frais notaire (EUR)',
    'Travaux (EUR)',
    'Apport (EUR)',
    'Montant emprunte (EUR)',
    'Taux (%)',
    'Duree pret (ans)',
    'Mensualite (EUR)',
    'Loyer annuel brut (EUR)',
    'Charges annuelles (EUR)',
    'Rendement brut (%)',
    'Rendement net (%)',
    'Cash-flow mensuel (EUR)',
    "Score d'investissement",
  ];

  static Future<bool> exportBiens(List<SavedProperty> biens) async {
    final buffer = StringBuffer();
    buffer.writeln(_headers.map(_field).join(';'));
    for (final b in biens) {
      final f = b.form;
      final c = b.core;
      buffer.writeln([
        _field(f.nom.isEmpty ? 'Bien sans nom' : f.nom),
        _field(f.commune?.nom ?? ''),
        _field(f.mode == RentalMode.longue ? 'Longue duree' : 'Courte duree'),
        _num(f.prix),
        _num(f.surface),
        _num(c.prixM2),
        _num(f.notaire),
        _num(f.travaux),
        _num(c.apport),
        _num(c.montantEmprunte),
        _num(f.tauxPct),
        f.dureePretAns.toString(),
        _num(c.mensualite),
        _num(c.loyerAnnuelBrut),
        _num(c.chargesAnnuelles),
        _num(c.brut),
        _num(c.net),
        _num(c.cashflowMensuel),
        b.score.score.toString(),
      ].join(';'));
    }

    // BOM UTF-8 : sans lui, Excel affiche les accents et le symbole € comme
    // des caractères corrompus au lieu de détecter l'encodage correctement.
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(buffer.toString())]);
    return saveBytes(bytes: bytes, filename: 'didou-immo-patrimoine.csv', mimeType: 'text/csv;charset=utf-8');
  }

  static String _num(double v) => v.toStringAsFixed(2);

  static String _field(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
