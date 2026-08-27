import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculations.dart';
import '../../utils/formatters.dart';
import '../../widgets/number_field.dart';
import '../../widgets/section_title.dart';
import '../../widgets/tip.dart';

/// Onglet "Projection" — équivalent de `ProjectionScreen` du prototype.
class ProjectionScreen extends StatefulWidget {
  const ProjectionScreen({super.key});

  @override
  State<ProjectionScreen> createState() => _ProjectionScreenState();
}

class _ProjectionScreenState extends State<ProjectionScreen> {
  bool _showAmortissement = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    final form = state.form;
    final core = state.core;
    final projection = state.projection;
    final isNovice = state.niveau == NiveauMode.novice;

    final last = projection.last;
    final first = projection.first;
    final plusValueEquity = last.equity - first.equity;
    final revente = computePlusValue(form, core, last.valeurBien, form.dureeProjection);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SectionTitle('Projection patrimoniale'),
        Text("Évolution de la valeur et du capital restant dû",
            style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.45))),
        const SizedBox(height: 12),
        Row(
          children: [10, 15, 20].map((y) {
            final active = form.dureeProjection == y;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => state.updateForm((f) => f.copyWith(dureeProjection: y)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text('$y ans', style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.ink)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: NumberField(label: 'Croissance loyers', value: form.croissanceLoyer, suffix: '%/an', onChanged: (v) => state.updateForm((f) => f.copyWith(croissanceLoyer: v)))),
          const SizedBox(width: 12),
          Expanded(child: NumberField(label: 'Croissance valeur bien', value: form.croissanceValeur, suffix: '%/an', onChanged: (v) => state.updateForm((f) => f.copyWith(croissanceValeur: v)))),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.ink, AppColors.accent]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PATRIMOINE NET APRÈS ${form.dureeProjection} ANS', style: AppTextStyles.sans(fontSize: 11, color: Colors.white70, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(eur(last.equity), style: AppTextStyles.mono(fontSize: 36, color: const Color(0xFFEDE6D2))),
            const SizedBox(height: 4),
            Text('soit +${eur(plusValueEquity)} de patrimoine constitué', style: AppTextStyles.sans(fontSize: 12, color: Colors.white70)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(children: [
            SizedBox(height: 200, child: _buildChart(projection)),
            const SizedBox(height: 4),
            Wrap(spacing: 16, alignment: WrapAlignment.center, children: [
              _legendDot('Valeur du bien', AppColors.gold),
              _legendDot('Capital restant dû', AppColors.alert),
              _legendDot('Patrimoine net', AppColors.accent),
            ]),
          ]),
        ),
        InkWell(
          onTap: () => setState(() => _showAmortissement = !_showAmortissement),
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: EdgeInsets.only(bottom: _showAmortissement ? 0 : 24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.table_chart_outlined, size: 15, color: AppColors.accent),
                const SizedBox(width: 8),
                Text("Tableau d'amortissement du prêt", style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
              ]),
              Icon(_showAmortissement ? Icons.expand_less : Icons.expand_more, color: AppColors.ink.withValues(alpha: 0.4)),
            ]),
          ),
        ),
        if (_showAmortissement) _buildAmortissementTable(state.amortissement),
        const SectionTitle('Simulation de revente'),
        if (isNovice)
          Tip('Si tu revends après ${form.dureeProjection} ans, une partie de la plus-value réalisée est taxée — mais l\'impôt diminue plus tu gardes le bien longtemps, jusqu\'à disparaître après 22 à 30 ans.'),
        NumberField(
          label: "Frais d'agence à la revente",
          value: form.fraisAgenceRevente,
          suffix: '%',
          hint: 'vente projetée dans ${form.dureeProjection} ans',
          onChanged: (v) => state.updateForm((f) => f.copyWith(fraisAgenceRevente: v)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(children: [
            if (!isNovice) ...[
              _reventeRow('Prix de vente net (frais agence déduits)', eur(revente.prixVenteNet), AppColors.ink),
              _reventeRow('Plus-value brute', eur(revente.plusValueBrute), AppColors.ink),
              _reventeRow('Impôt (19 %, après ${fmt(revente.abIR * 100, 0)}% d\'abattement)', '-${eur(revente.impotIR)}', AppColors.alert),
              _reventeRow('Prélèvements sociaux (17,2 %, après ${fmt(revente.abPS * 100, 0)}% d\'abattement)', '-${eur(revente.impotPS)}', AppColors.alert),
              Container(margin: const EdgeInsets.symmetric(vertical: 6), height: 1, color: AppColors.border),
            ],
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Plus-value nette estimée', style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
              Text(eur(revente.plusValueNette), style: AppTextStyles.mono(fontSize: 16, color: AppColors.accent)),
            ]),
          ]),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 13, color: AppColors.ink.withValues(alpha: 0.5))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Régime des particuliers, simplifié (les SCI à l'IS et le LMNP suivent d'autres règles). Projection basée sur une croissance constante — estimation indicative uniquement.",
              style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildChart(List<ProjectionPoint> projection) {
    List<FlSpot> spotsFor(double Function(ProjectionPoint) pick) =>
        projection.map((p) => FlSpot(p.year.toDouble(), pick(p))).toList();

    final allValues = projection.expand((p) => [p.valeurBien, p.capitalRestant, p.equity]);
    final maxY = allValues.fold<double>(0, (a, b) => a > b ? a : b);
    final minY = allValues.fold<double>(0, (a, b) => a < b ? a : b);

    return LineChart(
      LineChartData(
        minY: minY < 0 ? minY * 1.1 : 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.1,
        gridData: FlGridData(show: true, horizontalInterval: (maxY - minY) / 4, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${value.toInt()}a', style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.55))),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${(value / 1000).round()}k', style: AppTextStyles.sans(fontSize: 9, color: AppColors.ink.withValues(alpha: 0.55))),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem('${eur(s.y)}\nAnnée ${s.x.toInt()}', AppTextStyles.sans(fontSize: 11, color: AppColors.ink)))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(spots: spotsFor((p) => p.valeurBien), color: AppColors.gold, barWidth: 2, dotData: const FlDotData(show: false)),
          LineChartBarData(spots: spotsFor((p) => p.capitalRestant), color: AppColors.alert, barWidth: 2, dotData: const FlDotData(show: false)),
          LineChartBarData(spots: spotsFor((p) => p.equity), color: AppColors.accent, barWidth: 2.5, dotData: const FlDotData(show: false)),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 6),
      Text(label, style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.6))),
    ]);
  }

  Widget _buildAmortissementTable(List<AmortissementRow> rows) {
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Text("Renseigne un montant emprunté et un taux pour voir le détail année par année.",
            style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.5))),
      );
    }
    const colWidth = 84.0;
    Widget cell(String text, {bool header = false}) => SizedBox(
          width: colWidth,
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: header
                ? AppTextStyles.sans(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.ink.withValues(alpha: 0.5))
                : AppTextStyles.mono(fontSize: 11.5, color: AppColors.ink),
          ),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(width: 40, child: Text('AN', style: AppTextStyles.sans(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.ink.withValues(alpha: 0.5)))),
            cell('Intérêts', header: true),
            cell('Capital', header: true),
            cell('Restant dû', header: true),
          ]),
          Container(margin: const EdgeInsets.symmetric(vertical: 6), height: 1, color: AppColors.border),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  SizedBox(width: 40, child: Text('${r.annee}', style: AppTextStyles.mono(fontSize: 11.5, color: AppColors.ink))),
                  cell(eur(r.interets)),
                  cell(eur(r.capitalRembourse)),
                  cell(eur(r.capitalRestant)),
                ]),
              )),
        ]),
      ),
    );
  }

  Widget _reventeRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(label, style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.7)))),
        Text(value, style: AppTextStyles.mono(fontSize: 13, color: color)),
      ]),
    );
  }
}
