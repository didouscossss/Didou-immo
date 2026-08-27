import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/calculations.dart';
import '../utils/formatters.dart';

/// Génère et propose l'export PDF du bien actuellement à l'étude — chiffres
/// clés, régimes fiscaux, tableau d'amortissement. Purement client (pas de
/// serveur) : `printing` ouvre un aperçu/partage/impression natif, aussi
/// bien sur le web (téléchargement) que sur Android (feuille de partage).
class PdfExportService {
  static Future<void> exportBien({
    required PropertyInput form,
    required CoreResult core,
    required List<RegimeResult> regimes,
    required List<AmortissementRow> amortissement,
    required ScoreResult score,
  }) async {
    final bytes = await _build(form, core, regimes, amortissement, score);
    final nomFichier = 'didou-immo-${form.nom.isEmpty ? "bien" : _slug(form.nom)}.pdf';
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: nomFichier);
  }

  static String _slug(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');

  static Future<Uint8List> _build(
    PropertyInput form,
    CoreResult core,
    List<RegimeResult> regimes,
    List<AmortissementRow> amortissement,
    ScoreResult score,
  ) async {
    // Les polices de base du PDF (Helvetica) n'ont pas le glyphe "€" —
    // sans police Unicode, il s'affichait comme un carré vide. NotoSans le
    // couvre, comme la plupart des caractères latins étendus.
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final doc = pw.Document(theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont));
    final accent = PdfColor.fromHex('#2F5D50');
    final ink = PdfColor.fromHex('#16211C');
    final border = PdfColor.fromHex('#E4DDC9');

    pw.Widget statBlock(String label, String value) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: ink)),
          ],
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Didou Immo — Rendement', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            pw.SizedBox(height: 4),
            pw.Text(
              form.nom.isEmpty ? 'Bien sans nom' : form.nom,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: ink),
            ),
            pw.Text(
              '${form.commune?.nom ?? 'Commune non renseignée'} · '
              '${form.mode == RentalMode.longue ? 'Longue durée' : 'Courte durée'}'
              '${form.mode == RentalMode.longue ? (form.meuble ? ' · Meublé' : ' · Nu') : ''} · '
              '${eur(form.prix)} · ${fmt(form.surface, 0)} m²',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.Divider(color: border),
          ],
        ),
        footer: (context) => pw.Column(children: [
          pw.Divider(color: border),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Chiffres indicatifs — à vérifier avant toute décision d\'investissement.',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              pw.Text('Page ${context.pageNumber}/${context.pagesCount}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ],
          ),
        ]),
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.Text('Chiffres clés', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: accent)),
          pw.SizedBox(height: 8),
          pw.Wrap(spacing: 24, runSpacing: 10, children: [
            statBlock('Rentabilité brute', '${fmt(core.brut, 2)}%'),
            statBlock('Rentabilité nette', '${fmt(core.net, 2)}%'),
            statBlock('Cash-flow /mois', '${core.cashflowMensuel >= 0 ? '+' : ''}${fmt(core.cashflowMensuel)} €'),
            statBlock('Mensualité', eur(core.mensualite)),
            statBlock('Apport', eur(core.apport)),
            statBlock('Montant emprunté', eur(core.montantEmprunte)),
            statBlock("Score d'investissement", '${score.score}/100 · ${score.label}'),
          ]),
          pw.SizedBox(height: 20),
          pw.Text('Régimes fiscaux', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: accent)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: accent),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.center,
            },
            headers: const ['Régime', 'Base imposable', 'Impôt estimé/an', 'Revenu net-net', 'Éligible'],
            data: regimes
                .map((r) => [r.label, eur(r.base), eur(r.impot), eur(r.revenuNetNet), r.eligible ? 'Oui' : 'Non'])
                .toList(),
          ),
          pw.SizedBox(height: 20),
          if (amortissement.isNotEmpty) ...[
            pw.Text("Tableau d'amortissement du prêt", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: accent)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: accent),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              headers: const ['Année', 'Intérêts', 'Capital remboursé', 'Capital restant dû'],
              data: amortissement
                  .map((r) => [r.annee.toString(), eur(r.interets), eur(r.capitalRembourse), eur(r.capitalRestant)])
                  .toList(),
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }
}
