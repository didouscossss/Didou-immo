import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/saved_property.dart';
import '../../services/csv_export_service.dart';
import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculations.dart';
import '../../utils/formatters.dart';
import '../../widgets/compare_bar.dart';
import '../../widgets/score_badge.dart';
import '../../widgets/section_title.dart';

/// Onglet "Comparer" — équivalent de `BiensScreen` du prototype.
class BiensScreen extends StatefulWidget {
  /// Appelé quand on tape sur un bien pour le recharger dans le calculateur
  /// (voir `RendementState.loadPropertyForEditing`) — l'appelant (voir
  /// `RendementHome`) est responsable de basculer sur l'onglet "Bien".
  final VoidCallback? onEdit;
  const BiensScreen({super.key, this.onEdit});

  @override
  State<BiensScreen> createState() => _BiensScreenState();
}

class _BiensScreenState extends State<BiensScreen> {
  bool _showHistorique = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    final biens = state.biens;

    if (biens.isEmpty) {
      final error = state.cloudError;
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
              child: Icon(error == null ? Icons.layers_outlined : Icons.error_outline,
                  size: 26, color: error == null ? AppColors.accent : AppColors.alert),
            ),
            Text(error == null ? 'Aucun bien enregistré' : "Impossible de charger tes biens",
                textAlign: TextAlign.center, style: AppTextStyles.serif(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text(
                error ?? 'Calcule la rentabilité d\'un bien puis enregistre-le pour le comparer ici.',
                textAlign: TextAlign.center, style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.5))),
          ]),
        ),
      );
    }

    final sorted = [...biens]..sort((a, b) => b.score.score.compareTo(a.score.score));
    // La vue consolidée ne compte que le patrimoine actuellement détenu : un
    // projet à l'étude n'en fait pas encore partie, un bien vendu n'en fait
    // plus partie (son gain rejoint l'historique des ventes à la place).
    final achetes = biens.where((b) => b.form.achete && !b.form.vendu).toList();
    final vendus = biens.where((b) => b.form.vendu).toList()
      ..sort((a, b) => (b.form.dateVente ?? DateTime(0)).compareTo(a.form.dateVente ?? DateTime(0)));
    final enEtude = biens.length - achetes.length - vendus.length;
    final totalPatrimoine = achetes.fold<double>(0, (s, b) => s + b.core.prixTotal);
    final totalDette = achetes.fold<double>(0, (s, b) => s + b.core.montantEmprunte);
    final totalCashflow = achetes.fold<double>(0, (s, b) => s + b.core.cashflowMensuel);
    final scoreMoyen = achetes.isEmpty ? null : (achetes.fold<int>(0, (s, b) => s + b.score.score) / achetes.length).round();
    final gainsRealises = vendus.fold<double>(0, (s, b) => s + _plusValueReelle(b.form, b.core).plusValueNette);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SectionTitle('Comparatif'),
        Text('Classé par score d\'investissement', style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.45))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          margin: EdgeInsets.only(bottom: enEtude > 0 ? 6 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.ink, AppColors.accent]),
          ),
          child: achetes.isEmpty && vendus.isEmpty
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PATRIMOINE ACQUIS', style: AppTextStyles.sans(fontSize: 11, color: Colors.white70, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(
                    "Aucun bien encore marqué comme acquis — tape sur le badge d'un bien ci-dessous une fois l'achat conclu.",
                    style: AppTextStyles.sans(fontSize: 12.5, color: Colors.white70),
                  ),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    achetes.isEmpty
                        ? 'PATRIMOINE ACQUIS'
                        : 'PATRIMOINE ACQUIS · ${achetes.length} BIEN${achetes.length > 1 ? 'S' : ''}',
                    style: AppTextStyles.sans(fontSize: 11, color: Colors.white70, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  if (achetes.isEmpty)
                    Text('Plus aucun bien détenu actuellement — tous vendus ou encore à l\'étude.',
                        style: AppTextStyles.sans(fontSize: 12.5, color: Colors.white70))
                  else ...[
                    Row(children: [
                      Expanded(child: _statBlock('Patrimoine total', eur(totalPatrimoine))),
                      Expanded(child: _statBlock('Dette totale', eur(totalDette))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _statBlock('Cash-flow cumulé /mois', '${totalCashflow >= 0 ? '+' : ''}${fmt(totalCashflow)} €',
                          color: totalCashflow >= 0 ? const Color(0xFFEDE6D2) : const Color(0xFFE8B4A4))),
                      Expanded(child: _statBlock('Score moyen', '$scoreMoyen')),
                    ]),
                  ],
                  if (vendus.isNotEmpty) ...[
                    Container(margin: const EdgeInsets.symmetric(vertical: 12), height: 1, color: Colors.white24),
                    _statBlock(
                      'Plus-values réalisées · ${vendus.length} vente${vendus.length > 1 ? 's' : ''}',
                      '${gainsRealises >= 0 ? '+' : ''}${eur(gainsRealises)}',
                      color: gainsRealises >= 0 ? const Color(0xFFEDE6D2) : const Color(0xFFE8B4A4),
                    ),
                  ],
                ]),
        ),
        if (enEtude > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('+ $enEtude bien${enEtude > 1 ? 's' : ''} à l\'étude, pas encore comptabilisé${enEtude > 1 ? 's' : ''} dans le patrimoine ci-dessus.',
                style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5))),
          ),
        ...sorted.map((b) => InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                state.loadPropertyForEditing(b);
                widget.onEdit?.call();
              },
              child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Expanded(
                  child: Row(children: [
                    ScoreBadge(score: b.score.score, label: b.score.label, color: colorFromHex(b.score.colorHex), size: BadgeSize.sm),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Flexible(
                            child: Text(b.form.nom.isEmpty ? 'Bien sans nom' : b.form.nom,
                                overflow: TextOverflow.ellipsis, style: AppTextStyles.sans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                          ),
                          if (b.form.mode == RentalMode.courte) Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.bed_outlined, size: 11, color: AppColors.ink.withValues(alpha: 0.35))),
                        ]),
                        Text('${b.form.commune?.nom ?? '—'} · ${eur(b.form.prix)} · net ${fmt(b.core.net, 1)}%',
                            style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.45))),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                          _statusBadge(context, state, b),
                          if (b.form.achete && !b.form.vendu)
                            InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () => _marquerVendu(context, state, b),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
                                child: Text('Marquer vendu',
                                    style: AppTextStyles.sans(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.ink.withValues(alpha: 0.6))),
                              ),
                            ),
                        ]),
                      ]),
                    ),
                  ]),
                ),
                IconButton(
                  onPressed: () => state.deleteProperty(b.id),
                  icon: const Icon(Icons.delete_outline, size: 19),
                  color: AppColors.ink.withValues(alpha: 0.3),
                ),
              ]),
              ),
            )),
        const SizedBox(height: 6),
        if (state.niveau == NiveauMode.avance && biens.length > 1)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(children: [
              CompareBar(
                label: 'Rentabilité nette (%)',
                values: sorted.map((b) => CompareBarValue(b.form.nom.isEmpty ? 'Sans nom' : b.form.nom, b.core.net)).toList(),
                formatFn: (v) => '${fmt(v, 1)}%',
                color: AppColors.accent,
              ),
              CompareBar(
                label: 'Cash-flow mensuel (€)',
                values: sorted.map((b) => CompareBarValue(b.form.nom.isEmpty ? 'Sans nom' : b.form.nom, b.core.cashflowMensuel)).toList(),
                formatFn: eur,
                color: AppColors.gold,
              ),
              CompareBar(
                label: "Score d'investissement",
                values: sorted.map((b) => CompareBarValue(b.form.nom.isEmpty ? 'Sans nom' : b.form.nom, b.score.score.toDouble())).toList(),
                formatFn: (v) => v.round().toString(),
                color: AppColors.good,
              ),
            ]),
          ),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 13, color: AppColors.ink.withValues(alpha: 0.5))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Le score combine rendement, cash-flow, écart au marché local et taux d'occupation — un repère de comparaison, pas un conseil financier.",
              style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
            ),
          ),
        ]),
        if (vendus.isNotEmpty) ...[
          const SizedBox(height: 20),
          InkWell(
            onTap: () => setState(() => _showHistorique = !_showHistorique),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: _showHistorique ? 0 : 4),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Icon(Icons.history, size: 15, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Text('Historique des ventes (${vendus.length})', style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
                ]),
                Icon(_showHistorique ? Icons.expand_less : Icons.expand_more, color: AppColors.ink.withValues(alpha: 0.4)),
              ]),
            ),
          ),
          if (_showHistorique) ..._buildHistorique(vendus),
        ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.table_view_outlined, size: 15, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Exporter en CSV', style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
            ]),
            const SizedBox(height: 6),
            Text(
              "Génère un fichier avec tous tes biens enregistrés, un par ligne — à ouvrir dans un tableur pour croiser ou retravailler les chiffres toi-même.",
              style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _exportCsv(context, biens),
              icon: const Icon(Icons.ios_share, size: 15),
              label: const Text('Générer le CSV'),
            ),
          ]),
        ),
      ],
    );
  }

  /// Marquer un bien "acquis" demande la date d'achat (préremplie avec la
  /// précédente si déjà renseignée) — annuler le sélecteur n'a aucun effet.
  /// Revenir à "à l'étude" ne demande rien.
  Future<void> _toggleAchete(BuildContext context, RendementState state, SavedProperty b) async {
    if (b.form.achete) {
      state.setPropertyAchete(b.id, false);
      return;
    }
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: b.form.dateAchat ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: "Date d'achat",
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) {
      state.setPropertyAchete(b.id, true, dateAchat: picked);
    }
  }

  /// Badge de statut — à l'étude / acquis / vendu. Taper sur "Vendu" propose
  /// d'annuler la vente (retour à "acquis"), taper sur "À l'étude"/"Acquis"
  /// bascule l'un vers l'autre comme avant.
  Widget _statusBadge(BuildContext context, RendementState state, SavedProperty b) {
    final label = b.form.vendu
        ? 'Vendu${b.form.dateVente != null ? ' le ${dateFr(b.form.dateVente!)}' : ''}${b.form.prixVente != null ? ' · ${eur(b.form.prixVente)}' : ''}'
        : b.form.achete
            ? 'Acquis${b.form.dateAchat != null ? ' le ${dateFr(b.form.dateAchat!)}' : ''}'
            : 'À l\'étude';
    final color = b.form.vendu ? AppColors.gold : (b.form.achete ? AppColors.accent : AppColors.ink.withValues(alpha: 0.5));
    final icon = b.form.vendu ? Icons.sell_outlined : (b.form.achete ? Icons.check_circle : Icons.hourglass_top);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => b.form.vendu ? _annulerVente(context, state, b) : _toggleAchete(context, state, b),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: b.form.vendu || b.form.achete ? color.withValues(alpha: 0.12) : AppColors.border,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.sans(fontSize: 9.5, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  /// Demande le prix et la date de vente (préremplis si déjà renseignés une
  /// fois) via une mini boîte de dialogue — annuler n'a aucun effet.
  Future<void> _marquerVendu(BuildContext context, RendementState state, SavedProperty b) async {
    final result = await showDialog<({double prix, DateTime date})>(
      context: context,
      builder: (_) => _VenteDialog(prixInitial: b.form.prixVente, dateInitiale: b.form.dateVente, dateAchat: b.form.dateAchat),
    );
    if (result != null) {
      state.setPropertyVendu(b.id, true, dateVente: result.date, prixVente: result.prix);
    }
  }

  Future<void> _annulerVente(BuildContext context, RendementState state, SavedProperty b) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('Annuler cette vente ?', style: AppTextStyles.serif(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        content: Text('Le bien redevient "acquis" — le prix et la date de vente enregistrés seront perdus.',
            style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Garder')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Annuler la vente', style: TextStyle(color: AppColors.alert))),
        ],
      ),
    );
    if (confirme == true) {
      state.setPropertyVendu(b.id, false);
    }
  }

  /// Plus-value réelle à la revente — réutilise le même calcul que la
  /// simulation de revente projetée (onglet Projection), mais avec le prix
  /// et la durée de détention réels plutôt qu'estimés.
  PlusValueResult _plusValueReelle(PropertyInput f, CoreResult core) {
    final years = (f.dateAchat != null && f.dateVente != null)
        ? (f.dateVente!.difference(f.dateAchat!).inDays / 365.25).round().clamp(0, 100)
        : 0;
    return computePlusValue(f, core, f.prixVente ?? 0, years);
  }

  List<Widget> _buildHistorique(List<SavedProperty> vendus) {
    return [
      const SizedBox(height: 8),
      ...vendus.map((b) {
        final pv = _plusValueReelle(b.form, b.core);
        final gain = pv.plusValueNette;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.form.nom.isEmpty ? 'Bien sans nom' : b.form.nom,
                style: AppTextStyles.sans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
            Text(b.form.commune?.nom ?? '—', style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.45))),
            const SizedBox(height: 8),
            Text(
              'Acheté ${b.form.dateAchat != null ? 'le ${dateFr(b.form.dateAchat!)} ' : ''}pour ${eur(b.form.prix)} · vendu ${b.form.dateVente != null ? 'le ${dateFr(b.form.dateVente!)} ' : ''}pour ${eur(b.form.prixVente)}',
              style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Plus-value nette réalisée', style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.7))),
              Text('${gain >= 0 ? '+' : ''}${eur(gain)}',
                  style: AppTextStyles.mono(fontSize: 14, color: gain >= 0 ? AppColors.accent : AppColors.alert)),
            ]),
          ]),
        );
      }),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          "Plus-value estimée avec le taux de frais d'agence renseigné dans l'onglet Projection et le barème du régime des particuliers — à ajuster si ta situation réelle diffère.",
          style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.45)),
        ),
      ),
    ];
  }

  Future<void> _exportCsv(BuildContext context, List<SavedProperty> biens) async {
    final ok = await CsvExportService.exportBiens(biens);
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
}

/// Boîte de dialogue "Marquer vendu" — prix et date de vente. Renvoie `null`
/// si annulée, sinon le couple validé.
class _VenteDialog extends StatefulWidget {
  final double? prixInitial;
  final DateTime? dateInitiale;
  final DateTime? dateAchat;
  const _VenteDialog({this.prixInitial, this.dateInitiale, this.dateAchat});

  @override
  State<_VenteDialog> createState() => _VenteDialogState();
}

class _VenteDialogState extends State<_VenteDialog> {
  late final _prixController = TextEditingController(text: widget.prixInitial?.toStringAsFixed(0) ?? '');
  late DateTime _date = widget.dateInitiale ?? DateTime.now();

  @override
  void dispose() {
    _prixController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.dateAchat ?? DateTime(2000),
      lastDate: now,
      helpText: 'Date de vente',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final prix = double.tryParse(_prixController.text.replaceAll(',', '.').replaceAll(' ', ''));
    final valide = prix != null && prix > 0;
    return AlertDialog(
      backgroundColor: AppColors.paper,
      title: Text('Marquer ce bien vendu', style: AppTextStyles.serif(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Prix de vente', style: AppTextStyles.sans(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
        const SizedBox(height: 6),
        TextField(
          controller: _prixController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            suffixText: '€',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
          ),
          style: AppTextStyles.mono(fontSize: 15, color: const Color(0xFF16211C)),
        ),
        const SizedBox(height: 16),
        Text('Date de vente', style: AppTextStyles.sans(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
        const SizedBox(height: 6),
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
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        TextButton(
          onPressed: valide ? () => Navigator.of(context).pop((prix: prix, date: _date)) : null,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
