import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/saved_property.dart';
import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculations.dart';
import '../../utils/formatters.dart';
import '../../widgets/section_title.dart';

/// Onglet "Patrimoine" — suivi réel des biens ACQUIS (loyer réellement
/// perçu, charges réelles, vacance, travaux imprévus), par opposition à
/// l'onglet "Comparer" qui reste centré sur les projets à l'étude/en
/// prospection (et l'historique des ventes). Un bien peut apparaître dans
/// les deux : "Comparer" pour le score/comparatif, "Patrimoine" pour son
/// suivi réel dans le temps une fois détenu.
class PatrimoineScreen extends StatefulWidget {
  const PatrimoineScreen({super.key});

  @override
  State<PatrimoineScreen> createState() => _PatrimoineScreenState();
}

class _PatrimoineScreenState extends State<PatrimoineScreen> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    final actifs = state.biens.where((b) => b.form.achete && !b.form.vendu).toList()
      ..sort((a, b) => (b.form.dateAchat ?? DateTime(2000)).compareTo(a.form.dateAchat ?? DateTime(2000)));

    if (actifs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.insights_outlined, size: 26, color: AppColors.accent),
            ),
            Text('Aucun bien acquis pour le moment', textAlign: TextAlign.center, style: AppTextStyles.serif(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text(
              'Marque un bien "Acquis" depuis l\'onglet Comparer pour commencer à suivre ses chiffres réels ici.',
              textAlign: TextAlign.center,
              style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.5)),
            ),
          ]),
        ),
      );
    }

    final nbActifs = actifs.where((b) => _dernierCashFlow(b) >= 0).length;
    final nbPassifs = actifs.length - nbActifs;
    final cashFlowPortefeuille = actifs.fold<double>(0, (s, b) => s + _dernierCashFlow(b));
    final loyersRecusTotal = actifs.fold<double>(0, (s, b) => s + b.form.suivi.fold<double>(0, (s2, e) => s2 + (e.vacant ? 0 : (e.loyerPercu ?? 0))));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SectionTitle('Patrimoine'),
        Text('Suivi réel des biens acquis, par opposition aux hypothèses de départ',
            style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.45))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.ink, AppColors.accent]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${actifs.length} BIEN${actifs.length > 1 ? 'S' : ''} SUIVI${actifs.length > 1 ? 'S' : ''} · $nbActifs ACTIF${nbActifs > 1 ? 'S' : ''}, $nbPassifs PASSIF${nbPassifs > 1 ? 'S' : ''}',
                style: AppTextStyles.sans(fontSize: 11, color: Colors.white70, letterSpacing: 1)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _statBlock(
                  'Cash-flow réel cumulé /mois',
                  '${cashFlowPortefeuille >= 0 ? '+' : ''}${fmt(cashFlowPortefeuille)} €',
                  color: cashFlowPortefeuille >= 0 ? const Color(0xFFEDE6D2) : const Color(0xFFE8B4A4),
                ),
              ),
              Expanded(child: _statBlock('Loyers réels perçus (cumulé)', eur(loyersRecusTotal))),
            ]),
          ]),
        ),
        Text(
          'Un actif fait entrer plus d\'argent qu\'il n\'en coûte chaque mois (crédit compris), un passif en fait sortir. Basé sur le dernier relevé réel connu de chaque bien, ou sur l\'estimation théorique de départ tant qu\'aucun relevé n\'a été saisi.',
          style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 16),
        ...actifs.map((b) => _buildBienCard(context, state, b)),
      ],
    );
  }

  /// Dernier cash-flow réel connu (relevé le plus récent), ou repli sur le
  /// cash-flow théorique de l'onglet Bien tant qu'aucun relevé n'existe.
  double _dernierCashFlow(SavedProperty b) {
    if (b.form.suivi.isEmpty) return b.core.cashflowMensuel;
    return b.form.suivi.last.cashFlowReel(b.core.mensualite);
  }

  Widget _buildBienCard(BuildContext context, RendementState state, SavedProperty b) {
    final expanded = _expanded.contains(b.id);
    final cashFlow = _dernierCashFlow(b);
    final estActif = cashFlow >= 0;
    final aDesReleves = b.form.suivi.isNotEmpty;
    final nbVacants = b.form.suivi.where((e) => e.vacant).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => expanded ? _expanded.remove(b.id) : _expanded.add(b.id)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(b.form.nom.isEmpty ? 'Bien sans nom' : b.form.nom,
                          overflow: TextOverflow.ellipsis, style: AppTextStyles.sans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (estActif ? AppColors.good : AppColors.alert).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(estActif ? 'Actif' : 'Passif',
                          style: AppTextStyles.sans(fontSize: 9.5, fontWeight: FontWeight.w600, color: estActif ? AppColors.good : AppColors.alert)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    '${b.form.commune?.nom ?? '—'} · ${aDesReleves ? 'Cash-flow réel' : 'Estimation (aucun relevé)'} : ${cashFlow >= 0 ? '+' : ''}${fmt(cashFlow)} €/mois',
                    style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
                  ),
                ]),
              ),
              Icon(expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.ink.withValues(alpha: 0.4)),
            ]),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 16),
              if (b.form.suivi.length >= 2) ...[
                SizedBox(height: 160, child: _buildChart(b)),
                const SizedBox(height: 12),
              ],
              Row(children: [
                Expanded(child: _miniStat('Relevés', '${b.form.suivi.length}')),
                Expanded(child: _miniStat('Mois vacants', '$nbVacants')),
                Expanded(child: _miniStat('Mensualité crédit', eur(b.core.mensualite))),
              ]),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _ajouterReleve(context, state, b),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter un relevé'),
              ),
              if (b.form.suivi.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...b.form.suivi.reversed.map((e) => _releveRow(context, state, b, e)),
              ],
            ]),
          ),
      ]),
    );
  }

  Widget _releveRow(BuildContext context, RendementState state, SavedProperty b, SuiviEntry e) {
    final cf = e.cashFlowReel(b.core.mensualite);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dateFr(e.date), style: AppTextStyles.mono(fontSize: 12, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(
              e.vacant
                  ? 'Vacant${e.chargesReelles != null ? ' · charges ${eur(e.chargesReelles)}' : ''}'
                  : 'Loyer ${eur(e.loyerPercu ?? 0)}${e.chargesReelles != null ? ' · charges ${eur(e.chargesReelles)}' : ''}${e.travauxImprevus != null ? ' · imprévu ${eur(e.travauxImprevus)}' : ''}',
              style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.55)),
            ),
            if (e.note?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(e.note!, style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.45))),
              ),
          ]),
        ),
        Text('${cf >= 0 ? '+' : ''}${fmt(cf)} €', style: AppTextStyles.mono(fontSize: 12.5, color: cf >= 0 ? AppColors.good : AppColors.alert)),
        IconButton(
          onPressed: () => state.deleteSuiviEntry(b.id, e),
          icon: const Icon(Icons.close, size: 16),
          color: AppColors.ink.withValues(alpha: 0.3),
          visualDensity: VisualDensity.compact,
        ),
      ]),
    );
  }

  Widget _buildChart(SavedProperty b) {
    final entries = b.form.suivi;
    final spots = [
      for (var i = 0; i < entries.length; i++) FlSpot(i.toDouble(), entries[i].cashFlowReel(b.core.mensualite)),
    ];
    final values = spots.map((s) => s.y);
    final maxY = values.fold<double>(0, (a, v) => a > v ? a : v);
    final minY = values.fold<double>(0, (a, v) => a < v ? a : v);

    return LineChart(
      LineChartData(
        minY: minY < 0 ? minY * 1.2 : minY * 0.8,
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: FlGridData(show: true, horizontalInterval: ((maxY - minY).abs() / 3).clamp(1, double.infinity), getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (entries.length / 4).clamp(1, double.infinity).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(dateFrCourt(entries[i].date), style: AppTextStyles.sans(fontSize: 9, color: AppColors.ink.withValues(alpha: 0.5))),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.round()}€', style: AppTextStyles.sans(fontSize: 9, color: AppColors.ink.withValues(alpha: 0.55))),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            getTooltipItems: (touched) => touched.map((s) {
              final i = s.x.round();
              return LineTooltipItem('${eur(s.y)}\n${i >= 0 && i < entries.length ? dateFr(entries[i].date) : ''}',
                  AppTextStyles.sans(fontSize: 11, color: AppColors.ink));
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: AppColors.accent,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Future<void> _ajouterReleve(BuildContext context, RendementState state, SavedProperty b) async {
    final entry = await showDialog<SuiviEntry>(
      context: context,
      builder: (_) => const _SuiviDialog(),
    );
    if (entry != null) {
      await state.addSuiviEntry(b.id, entry);
    }
  }

  Widget _statBlock(String label, String value, {Color color = const Color(0xFFEDE6D2)}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AppTextStyles.sans(fontSize: 10, color: Colors.white54)),
      const SizedBox(height: 3),
      Text(value, style: AppTextStyles.mono(fontSize: 17, color: color)),
    ]);
  }

  Widget _miniStat(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.45))),
      const SizedBox(height: 2),
      Text(value, style: AppTextStyles.mono(fontSize: 13, color: AppColors.ink)),
    ]);
  }
}

/// Boîte de dialogue "Ajouter un relevé" — un seul champ obligatoire (la
/// date), tout le reste facultatif pour coller à une saisie libre, pas
/// forcément mensuelle ni complète à chaque fois.
class _SuiviDialog extends StatefulWidget {
  const _SuiviDialog();

  @override
  State<_SuiviDialog> createState() => _SuiviDialogState();
}

class _SuiviDialogState extends State<_SuiviDialog> {
  DateTime _date = DateTime.now();
  bool _vacant = false;
  final _loyerController = TextEditingController();
  final _chargesController = TextEditingController();
  final _travauxController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _loyerController.dispose();
    _chargesController.dispose();
    _travauxController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? _parse(String s) => s.trim().isEmpty ? null : double.tryParse(s.replaceAll(',', '.').replaceAll(' ', ''));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Date du relevé',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      title: Text('Ajouter un relevé', style: AppTextStyles.serif(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.ink.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Text(dateFr(_date), style: AppTextStyles.mono(fontSize: 14, color: AppColors.ink)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _vacant,
            onChanged: (v) => setState(() => _vacant = v ?? false),
            title: Text('Bien vacant sur cette période', style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          if (!_vacant) ...[
            const SizedBox(height: 4),
            _field(_loyerController, 'Loyer réellement perçu'),
          ],
          const SizedBox(height: 12),
          _field(_chargesController, 'Charges réelles payées'),
          const SizedBox(height: 12),
          _field(_travauxController, 'Travaux / imprévu'),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Note (optionnel)',
              isDense: true,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(SuiviEntry(
            date: _date,
            loyerPercu: _vacant ? null : _parse(_loyerController.text),
            chargesReelles: _parse(_chargesController.text),
            vacant: _vacant,
            travauxImprevus: _parse(_travauxController.text),
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          )),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: '€',
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
      ),
      style: AppTextStyles.mono(fontSize: 14, color: AppColors.ink),
    );
  }
}
