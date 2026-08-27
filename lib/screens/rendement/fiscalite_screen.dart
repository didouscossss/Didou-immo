import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculations.dart';
import '../../utils/formatters.dart';
import '../../widgets/digit_readout.dart';
import '../../widgets/number_field.dart';
import '../../widgets/section_title.dart';
import '../../widgets/tip.dart';

/// Onglet "Fiscalité" — équivalent de `FiscaliteScreen` du prototype.
class FiscaliteScreen extends StatelessWidget {
  const FiscaliteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    final form = state.form;
    final regimes = state.regimes;
    final isNovice = state.niveau == NiveauMode.novice;

    final sorted = [...regimes]..sort((a, b) => b.netNetPct.compareTo(a.netNetPct));
    final top = sorted.firstWhere((r) => r.eligible, orElse: () => sorted.first);
    final checklist = form.mode == RentalMode.longue ? checklistLongue : checklistCourte;
    final deadlines = form.mode == RentalMode.longue ? deadlinesLongue : deadlinesCourte;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SectionTitle('Régimes fiscaux'),
        Text('Comparatif selon ta tranche d\'imposition',
            style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.45))),
        const SizedBox(height: 12),
        NumberField(
          label: "Tranche marginale d'imposition (TMI)",
          value: form.tmi,
          suffix: '%',
          onChanged: (v) => state.updateForm((f) => f.copyWith(tmi: v)),
        ),
        if (isNovice)
          const Tip(
              "C'est le taux d'impôt sur ta dernière tranche de revenu (0, 11, 30, 41 ou 45 %) — regarde ton dernier avis d'imposition si tu ne le connais pas."),
        const SizedBox(height: 16),
        if (isNovice)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('${top.label} semble le plus avantageux', style: AppTextStyles.sans(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink))),
              ]),
              const SizedBox(height: 6),
              DigitReadout(value: top.netNetPct, size: ReadoutSize.sm, accent: AppColors.accent),
              const SizedBox(height: 8),
              Text(top.note, style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))),
              const SizedBox(height: 8),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 8),
              Text(
                'Impôt estimé à environ ${eur(top.impot)}/an sur ce bien. Passe en mode avancé pour voir le détail du calcul et comparer tous les régimes.',
                style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.7)),
              ),
            ]),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              children: sorted.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: r.eligible ? 1 : 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(children: [
                        if (i == 0 && r.eligible)
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(right: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                        Text(r.label, style: AppTextStyles.sans(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
                      ]),
                      DigitReadout(value: r.netNetPct, size: ReadoutSize.sm, accent: r.eligible ? AppColors.accent : AppColors.ink.withValues(alpha: 0.4)),
                    ]),
                    const SizedBox(height: 6),
                    Text(r.note, style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5))),
                    const SizedBox(height: 8),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Base imposable : ${eur(r.base)}', style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.6))),
                      Text('Impôt estimé : ${eur(r.impot)}/an', style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.6))),
                    ]),
                    if (!r.eligible)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Non éligible dans cette configuration', style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.alert)),
                      ),
                  ]),
                );
              }).toList(),
            ),
          ),
        Row(children: [
          Icon(Icons.fact_check_outlined, size: 17, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Documents & démarches', style: AppTextStyles.serif(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(
            children: checklist
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item, style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink))),
                      ]),
                    ))
                .toList(),
          ),
        ),
        Row(children: [
          Icon(Icons.calendar_today_outlined, size: 17, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Échéances récurrentes', style: AppTextStyles.serif(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ]),
        const SizedBox(height: 12),
        ...deadlines.map((d) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(d.periode, style: AppTextStyles.sans(fontSize: 10, color: AppColors.accent)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(d.label, style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink))),
              ]),
            )),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.account_balance_outlined, size: 17, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Structure de détention', style: AppTextStyles.serif(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ]),
        const SizedBox(height: 12),
        if (isNovice)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Text(
              "Pour un premier investissement, l'achat en nom propre est en général le plus simple à démarrer. Des structures comme la SCI deviennent surtout utiles pour acheter à plusieurs ou préparer une transmission. Passe en mode avancé pour comparer les options en détail.",
              style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.75)),
            ),
          )
        else
          ...structures.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.label, style: AppTextStyles.sans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                  Text(s.subtitle, style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.45))),
                  const SizedBox(height: 8),
                  ...s.points.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(p, style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.75)))),
                        ]),
                      )),
                ]),
              )),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 13, color: AppColors.ink.withValues(alpha: 0.5))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Estimations et listes génériques à titre indicatif (barème TMI + 17,2 % prélèvements sociaux). Vérifie les règles en vigueur dans ta commune et auprès d\'un expert-comptable ou notaire — le choix de structure a des conséquences juridiques durables.',
              style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
            ),
          ),
        ]),
      ],
    );
  }
}
