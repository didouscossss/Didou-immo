import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final totalPatrimoine = biens.fold<double>(0, (s, b) => s + b.core.prixTotal);
    final totalDette = biens.fold<double>(0, (s, b) => s + b.core.montantEmprunte);
    final totalCashflow = biens.fold<double>(0, (s, b) => s + b.core.cashflowMensuel);
    final scoreMoyen = (biens.fold<int>(0, (s, b) => s + b.score.score) / biens.length).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SectionTitle('Comparatif'),
        Text('Classé par score d\'investissement', style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.45))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.ink, AppColors.accent]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('VUE CONSOLIDÉE · ${biens.length} BIEN${biens.length > 1 ? 'S' : ''}', style: AppTextStyles.sans(fontSize: 11, color: Colors.white70, letterSpacing: 1)),
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
        ...sorted.map((b) => InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                state.loadPropertyForEditing(b);
                onEdit?.call();
              },
              child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
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
                          if (b.form.mode == RentalMode.courte) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.bed_outlined, size: 11, color: Colors.black38)),
                        ]),
                        Text('${b.form.commune?.nom ?? '—'} · ${eur(b.form.prix)} · net ${fmt(b.core.net, 1)}%',
                            style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.45))),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
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
      ],
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
