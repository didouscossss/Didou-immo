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
class BiensScreen extends StatelessWidget {
  /// Appelé quand on tape sur un bien pour le recharger dans le calculateur
  /// (voir `RendementState.loadPropertyForEditing`) — l'appelant (voir
  /// `RendementHome`) est responsable de basculer sur l'onglet "Bien".
  final VoidCallback? onEdit;
  const BiensScreen({super.key, this.onEdit});

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
    // La vue consolidée ne compte que les biens marqués "acquis" — un projet
    // encore à l'étude ne fait pas (encore) partie du patrimoine réel.
    final achetes = biens.where((b) => b.form.achete).toList();
    final enEtude = biens.length - achetes.length;
    final totalPatrimoine = achetes.fold<double>(0, (s, b) => s + b.core.prixTotal);
    final totalDette = achetes.fold<double>(0, (s, b) => s + b.core.montantEmprunte);
    final totalCashflow = achetes.fold<double>(0, (s, b) => s + b.core.cashflowMensuel);
    final scoreMoyen = achetes.isEmpty ? null : (achetes.fold<int>(0, (s, b) => s + b.score.score) / achetes.length).round();

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
          child: achetes.isEmpty
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PATRIMOINE ACQUIS', style: AppTextStyles.sans(fontSize: 11, color: Colors.white70, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(
                    "Aucun bien encore marqué comme acquis — tape sur le badge d'un bien ci-dessous une fois l'achat conclu.",
                    style: AppTextStyles.sans(fontSize: 12.5, color: Colors.white70),
                  ),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PATRIMOINE ACQUIS · ${achetes.length} BIEN${achetes.length > 1 ? 'S' : ''}',
                      style: AppTextStyles.sans(fontSize: 11, color: Colors.white70, letterSpacing: 1)),
                  const SizedBox(height: 12),
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
                onEdit?.call();
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
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => _toggleAchete(context, state, b),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: b.form.achete ? AppColors.accent.withValues(alpha: 0.12) : AppColors.border,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(b.form.achete ? Icons.check_circle : Icons.hourglass_top,
                                  size: 11, color: b.form.achete ? AppColors.accent : AppColors.ink.withValues(alpha: 0.45)),
                              const SizedBox(width: 4),
                              Text(
                                b.form.achete
                                    ? 'Acquis${b.form.dateAchat != null ? ' le ${dateFr(b.form.dateAchat!)}' : ''}'
                                    : 'À l\'étude',
                                style: AppTextStyles.sans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: b.form.achete ? AppColors.accent : AppColors.ink.withValues(alpha: 0.5)),
                              ),
                            ]),
                          ),
                        ),
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
