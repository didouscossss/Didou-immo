import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/saved_property.dart';
import '../../services/csv_export_service.dart';
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
///
/// Chaque relevé porte une PÉRIODE (date de début, date de fin optionnelle —
/// vide = toujours en cours) plutôt qu'un simple point dans le temps : un
/// loyer qui change, une vacance puis une reprise à un loyer différent...
/// se lisent comme une vraie courbe en escalier, pas comme des points reliés
/// en ligne droite.
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
    final tousActifs = state.biens.where((b) => b.form.achete && !b.form.vendu).toList()
      ..sort((a, b) => (b.form.dateAchat ?? DateTime(2000)).compareTo(a.form.dateAchat ?? DateTime(2000)));

    if (tousActifs.isEmpty) {
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

    // La résidence principale n'est pas un investissement locatif : exclue
    // du cash-flow/actif-passif du portefeuille, mais garde sa carte et son
    // suivi (charges réelles...).
    final investissements = tousActifs.where((b) => !b.form.residencePrincipale).toList();
    final nbActifs = investissements.where((b) => _dernierCashFlow(b) >= 0).length;
    final nbPassifs = investissements.length - nbActifs;
    final cashFlowPortefeuille = investissements.fold<double>(0, (s, b) => s + _dernierCashFlow(b));
    final loyersRecusTotal = tousActifs.fold<double>(
        0, (s, b) => s + b.form.suivi.fold<double>(0, (s2, e) => s2 + (e.vacant ? 0 : (e.loyerPercu ?? 0))));
    final portefeuilleSpots = _buildPortefeuilleSpots(investissements);

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
            Text(
              '${investissements.length} INVESTISSEMENT${investissements.length > 1 ? 'S' : ''} · $nbActifs ACTIF${nbActifs > 1 ? 'S' : ''}, $nbPassifs PASSIF${nbPassifs > 1 ? 'S' : ''}'
              '${tousActifs.length > investissements.length ? ' · + RÉSIDENCE PRINCIPALE' : ''}',
              style: AppTextStyles.sans(fontSize: 11, color: Colors.white70, letterSpacing: 1),
            ),
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
            if (portefeuilleSpots.length >= 2) ...[
              const SizedBox(height: 16),
              SizedBox(height: 120, child: _buildPortefeuilleChart(portefeuilleSpots)),
            ],
          ]),
        ),
        Text(
          'Un actif fait entrer plus d\'argent qu\'il n\'en coûte chaque mois (crédit compris), un passif en fait sortir. Basé sur le dernier relevé réel connu de chaque bien, ou sur l\'estimation théorique de départ tant qu\'aucun relevé n\'a été saisi. La résidence principale n\'est pas comptée : ce n\'est pas un investissement locatif.',
          style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _exportCsv(context, tousActifs),
            icon: const Icon(Icons.ios_share, size: 14),
            label: const Text('Exporter les relevés (CSV)', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(height: 8),
        ...tousActifs.map((b) => _buildBienCard(context, state, b)),
      ],
    );
  }

  /// Dernier cash-flow réel connu (relevé le plus récent), ou repli sur le
  /// cash-flow théorique de l'onglet Bien tant qu'aucun relevé n'existe.
  double _dernierCashFlow(SavedProperty b) {
    if (b.form.suivi.isEmpty) return b.core.cashflowMensuel;
    return b.form.suivi.last.cashFlowReel(b.core.mensualite);
  }

  /// Cash-flow réel "à la date [d]" pour un bien : la période qui couvre
  /// cette date si elle existe, sinon le cash-flow théorique (aucun relevé
  /// encore saisi pour cette période de la vie du bien).
  double _cashFlowA(SavedProperty b, DateTime d) {
    for (final e in b.form.suivi) {
      if (e.couvre(d)) return e.cashFlowReel(b.core.mensualite);
    }
    return b.core.cashflowMensuel;
  }

  /// Reconstruit une série temporelle du cash-flow réel CUMULÉ du
  /// portefeuille, à partir de l'union des dates de début/fin de toutes les
  /// périodes de tous les biens — une approximation "en escalier", pas une
  /// vraie moyenne continue, mais qui suit fidèlement chaque changement.
  List<FlSpot> _buildPortefeuilleSpots(List<SavedProperty> biens) {
    if (biens.isEmpty) return const [];
    final dates = <DateTime>{};
    for (final b in biens) {
      for (final e in b.form.suivi) {
        dates.add(e.dateDebut);
        dates.add(e.dateFin ?? DateTime.now());
      }
    }
    if (dates.length < 2) return const [];
    final sorted = dates.toList()..sort();
    final origin = sorted.first;
    return [
      for (final d in sorted) FlSpot(d.difference(origin).inDays.toDouble(), biens.fold<double>(0, (s, b) => s + _cashFlowA(b, d))),
    ];
  }

  Widget _buildPortefeuilleChart(List<FlSpot> spots) {
    final origin = DateTime.now().subtract(Duration(days: spots.last.x.toInt()));
    final values = spots.map((s) => s.y);
    final maxY = values.fold<double>(0, (a, v) => a > v ? a : v);
    final minY = values.fold<double>(0, (a, v) => a < v ? a : v);
    return LineChart(
      LineChartData(
        minY: minY < 0 ? minY * 1.2 : minY * 0.8,
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: (spots.last.x / 3).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(dateFrCourt(origin.add(Duration(days: value.round()))), style: AppTextStyles.sans(fontSize: 9, color: Colors.white54)),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.ink,
            getTooltipItems: (touched) => touched
                .map((s) => LineTooltipItem(
                    '${eur(s.y)}\n${dateFr(origin.add(Duration(days: s.x.round())))}', const TextStyle(fontSize: 11, color: Colors.white)))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(spots: spots, color: const Color(0xFFEDE6D2), barWidth: 2.5, isStepLineChart: true, dotData: const FlDotData(show: false)),
        ],
      ),
    );
  }

  Widget _buildBienCard(BuildContext context, RendementState state, SavedProperty b) {
    final expanded = _expanded.contains(b.id);
    final estResidence = b.form.residencePrincipale;
    final cashFlow = _dernierCashFlow(b);
    final estActif = cashFlow >= 0;
    final aDesReleves = b.form.suivi.isNotEmpty;
    final nbVacants = b.form.suivi.where((e) => e.vacant).length;
    final ecart = computeEcartReelPrevu(b.form, b.form.suivi.isEmpty ? null : b.form.suivi.last);

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
                        color: (estResidence ? AppColors.gold : (estActif ? AppColors.good : AppColors.alert)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(estResidence ? 'Résidence principale' : (estActif ? 'Actif' : 'Passif'),
                          style: AppTextStyles.sans(
                              fontSize: 9.5, fontWeight: FontWeight.w600, color: estResidence ? AppColors.gold : (estActif ? AppColors.good : AppColors.alert))),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    estResidence
                        ? (b.form.commune?.nom ?? '—')
                        : '${b.form.commune?.nom ?? '—'} · ${aDesReleves ? 'Cash-flow réel' : 'Estimation (aucun relevé)'} : ${cashFlow >= 0 ? '+' : ''}${fmt(cashFlow)} €/mois',
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
              if (b.form.suivi.isNotEmpty) ...[
                Text('Loyer réel dans le temps', style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink)),
                const SizedBox(height: 8),
                SizedBox(height: 150, child: _buildChart(b)),
                const SizedBox(height: 16),
              ],
              Row(children: [
                Expanded(child: _miniStat('Relevés', '${b.form.suivi.length}')),
                Expanded(child: _miniStat('Mois vacants', '$nbVacants')),
                Expanded(child: _miniStat('Mensualité crédit', eur(b.core.mensualite))),
              ]),
              if (ecart != null) ...[
                const SizedBox(height: 16),
                Text('Réel vs prévu (dernier relevé)', style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink)),
                const SizedBox(height: 8),
                _ecartRow('Loyer', ecart.loyerTheorique, ecart.loyerReel, plusEstMieux: true),
                _ecartRow('Copro', ecart.coproTheorique, ecart.coproReel, plusEstMieux: false),
                _ecartRow('Taxe foncière', ecart.taxeFonciereTheorique, ecart.taxeFonciereReel, plusEstMieux: false),
                _ecartRow('Assurance', ecart.assuranceTheorique, ecart.assuranceReel, plusEstMieux: false),
              ],
              const SizedBox(height: 16),
              CheckboxListTile(
                value: estResidence,
                onChanged: (v) => state.setResidencePrincipale(b.id, v ?? false),
                title: Text("C'est notre résidence principale (pas un investissement locatif)",
                    style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _ajouterOuModifierReleve(context, state, b, null),
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

  Widget _ecartRow(String label, double theorique, double reel, {required bool plusEstMieux}) {
    final delta = reel - theorique;
    final bon = plusEstMieux ? delta >= 0 : delta <= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label, style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.7)))),
        Expanded(flex: 2, child: Text('prévu ${eur(theorique)}', textAlign: TextAlign.right, style: AppTextStyles.mono(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)))),
        Expanded(
          flex: 2,
          child: Text('réel ${eur(reel)}',
              textAlign: TextAlign.right, style: AppTextStyles.mono(fontSize: 11.5, fontWeight: FontWeight.w600, color: bon ? AppColors.good : AppColors.alert)),
        ),
      ]),
    );
  }

  Widget _releveRow(BuildContext context, RendementState state, SavedProperty b, SuiviEntry e) {
    final cf = e.cashFlowReel(b.core.mensualite);
    final periode = '${dateFr(e.dateDebut)} → ${e.dateFin != null ? dateFr(e.dateFin!) : 'en cours'}';
    return InkWell(
      onTap: () => _ajouterOuModifierReleve(context, state, b, e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(periode, style: AppTextStyles.mono(fontSize: 12, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(
                e.vacant
                    ? 'Vacant${e.chargesReellesTotal > 0 ? ' · charges ${eur(e.chargesReellesTotal)}' : ''}'
                    : 'Loyer ${eur(e.loyerPercu ?? 0)}${e.chargesReellesTotal > 0 ? ' · charges ${eur(e.chargesReellesTotal)}' : ''}${e.travauxImprevus != null ? ' · imprévu ${eur(e.travauxImprevus)}' : ''}',
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
      ),
    );
  }

  /// Courbe en escalier du loyer réel (0 si vacant) dans le temps, pour QUE
  /// une vacance suivie d'une reprise à un loyer différent se voie
  /// clairement — deux points par période (début et fin) plutôt qu'un point
  /// par relevé, pour que l'axe du temps reflète la vraie durée de chaque
  /// période, pas juste leur ordre.
  Widget _buildChart(SavedProperty b) {
    final entries = b.form.suivi;
    final origin = entries.first.dateDebut;
    double x(DateTime d) => d.difference(origin).inDays.toDouble();

    final spots = <FlSpot>[];
    for (final e in entries) {
      final valeur = e.vacant ? 0.0 : (e.loyerPercu ?? 0);
      spots.add(FlSpot(x(e.dateDebut), valeur));
      spots.add(FlSpot(x(e.dateFin ?? DateTime.now()), valeur));
    }
    final maxY = spots.map((s) => s.y).fold<double>(0, (a, v) => a > v ? a : v);
    final maxX = spots.isEmpty ? 1.0 : spots.last.x;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: FlGridData(show: true, horizontalInterval: (maxY / 3).clamp(1, double.infinity), getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: (maxX / 4).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(dateFrCourt(origin.add(Duration(days: value.round()))), style: AppTextStyles.sans(fontSize: 9, color: AppColors.ink.withValues(alpha: 0.5))),
              ),
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
            getTooltipItems: (touched) => touched
                .map((s) => LineTooltipItem('${eur(s.y)}\n${dateFr(origin.add(Duration(days: s.x.round())))}', AppTextStyles.sans(fontSize: 11, color: AppColors.ink)))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(spots: spots, color: AppColors.accent, barWidth: 2.5, dotData: const FlDotData(show: false)),
        ],
      ),
    );
  }

  Future<void> _ajouterOuModifierReleve(BuildContext context, RendementState state, SavedProperty b, SuiviEntry? existant) async {
    final entry = await showDialog<SuiviEntry>(
      context: context,
      builder: (_) => _SuiviDialog(existant: existant),
    );
    if (entry == null) return;
    if (existant != null) {
      await state.updateSuiviEntry(b.id, existant, entry);
    } else {
      await state.addSuiviEntry(b.id, entry);
    }
  }

  Future<void> _exportCsv(BuildContext context, List<SavedProperty> biens) async {
    final ok = await CsvExportService.exportSuivi(biens);
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Export CSV indisponible sur cette plateforme pour l'instant.")),
    );
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

/// Boîte de dialogue "Ajouter/Modifier un relevé" — seule la date de début
/// est obligatoire, tout le reste facultatif pour coller à une saisie
/// libre, pas forcément mensuelle ni complète à chaque fois.
class _SuiviDialog extends StatefulWidget {
  final SuiviEntry? existant;
  const _SuiviDialog({this.existant});

  @override
  State<_SuiviDialog> createState() => _SuiviDialogState();
}

class _SuiviDialogState extends State<_SuiviDialog> {
  late DateTime _dateDebut = widget.existant?.dateDebut ?? DateTime.now();
  DateTime? _dateFin;
  late bool _vacant = widget.existant?.vacant ?? false;
  late final _loyerController = TextEditingController(text: _fmt(widget.existant?.loyerPercu));
  late final _coproController = TextEditingController(text: _fmt(widget.existant?.chargesCoproReelles));
  late final _taxeController = TextEditingController(text: _fmt(widget.existant?.taxeFonciereReelle));
  late final _assuranceController = TextEditingController(text: _fmt(widget.existant?.assuranceReelle));
  late final _travauxController = TextEditingController(text: _fmt(widget.existant?.travauxImprevus));
  late final _noteController = TextEditingController(text: widget.existant?.note ?? '');

  static String _fmt(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());

  @override
  void initState() {
    super.initState();
    _dateFin = widget.existant?.dateFin;
  }

  @override
  void dispose() {
    _loyerController.dispose();
    _coproController.dispose();
    _taxeController.dispose();
    _assuranceController.dispose();
    _travauxController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? _parse(String s) => s.trim().isEmpty ? null : double.tryParse(s.replaceAll(',', '.').replaceAll(' ', ''));

  Future<void> _pickDateDebut() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateDebut,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Depuis le',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) setState(() => _dateDebut = picked);
  }

  Future<void> _pickDateFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFin ?? _dateDebut,
      firstDate: _dateDebut,
      lastDate: DateTime(2100),
      helpText: 'Jusqu\'au',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) setState(() => _dateFin = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      title: Text(widget.existant != null ? 'Modifier ce relevé' : 'Ajouter un relevé',
          style: AppTextStyles.serif(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _dateField('Depuis le', _dateDebut, _pickDateDebut)),
            const SizedBox(width: 8),
            Expanded(
              child: _dateField('Jusqu\'au', _dateFin, _pickDateFin,
                  placeholder: 'En cours', onClear: _dateFin == null ? null : () => setState(() => _dateFin = null)),
            ),
          ]),
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
          Text('Charges réelles (par poste)', style: AppTextStyles.sans(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.ink.withValues(alpha: 0.6))),
          const SizedBox(height: 6),
          _field(_coproController, 'Copropriété'),
          const SizedBox(height: 8),
          _field(_taxeController, 'Taxe foncière'),
          const SizedBox(height: 8),
          _field(_assuranceController, 'Assurance'),
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
            dateDebut: _dateDebut,
            dateFin: _dateFin,
            loyerPercu: _vacant ? null : _parse(_loyerController.text),
            chargesCoproReelles: _parse(_coproController.text),
            taxeFonciereReelle: _parse(_taxeController.text),
            assuranceReelle: _parse(_assuranceController.text),
            vacant: _vacant,
            travauxImprevus: _parse(_travauxController.text),
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          )),
          child: Text(widget.existant != null ? 'Enregistrer' : 'Ajouter'),
        ),
      ],
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap, {String placeholder = '', VoidCallback? onClear}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.sans(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.ink.withValues(alpha: 0.6))),
      const SizedBox(height: 6),
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.ink.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(value != null ? dateFr(value) : placeholder,
                  overflow: TextOverflow.ellipsis, style: AppTextStyles.mono(fontSize: 12.5, color: AppColors.ink)),
            ),
            if (onClear != null)
              InkWell(onTap: onClear, child: Icon(Icons.close, size: 14, color: AppColors.ink.withValues(alpha: 0.4))),
          ]),
        ),
      ),
    ]);
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
