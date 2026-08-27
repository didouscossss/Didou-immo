import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculations.dart';
import '../../utils/formatters.dart';
import '../../widgets/commune_picker.dart';
import '../../widgets/digit_readout.dart';
import '../../widgets/mode_toggle.dart';
import '../../widgets/number_field.dart';
import '../../widgets/section_title.dart';
import '../../widgets/synced_text_field.dart';
import '../../widgets/tip.dart';
import '../../widgets/verdict_card.dart';

/// Onglet "Bien" — équivalent de `CalcScreen` du prototype.
class CalcScreen extends StatefulWidget {
  final VoidCallback onSave;
  const CalcScreen({super.key, required this.onSave});

  @override
  State<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends State<CalcScreen> {
  bool _stressTaux = false;
  bool _stressOccupation = false;
  bool _stressTravaux = false;
  // Amplitude de chaque scénario — librement réglable au lieu de valeurs
  // fixes (+1 point, -25 %, +5 000 €).
  double _stressTauxPts = 1;
  double _stressOccupationPct = 25;
  double _stressTravauxEuros = 5000;
  bool _showVisite = false;
  final Set<int> _visiteChecked = {};

  bool get _anyStress => _stressTaux || _stressOccupation || _stressTravaux;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    final form = state.form;
    final core = state.core;
    final comparaison = state.comparaison;
    final isNovice = state.niveau == NiveauMode.novice;

    void set(PropertyInput Function(PropertyInput f) updater) => state.updateForm(updater);

    final tauxDelta = _stressTaux ? _stressTauxPts : 0.0;
    final occDelta = _stressOccupation ? _stressOccupationPct : 0.0;
    final travauxDelta = _stressTravaux ? _stressTravauxEuros : 0.0;
    // Même pourcentage de "baisse d'occupation" appliqué de façon cohérente
    // aux deux modes : en longue durée sur le taux d'occupation déduit de
    // la vacance, en courte durée directement sur les nuits réservées.
    final stressForm = form.copyWith(
      tauxPct: form.tauxPct + tauxDelta,
      vacancePct: form.mode == RentalMode.longue
          ? (100 - (100 - form.vacancePct) * (1 - occDelta / 100)).clamp(0, 100).toDouble()
          : form.vacancePct,
      nuitsBasseSaison: form.mode == RentalMode.courte
          ? (form.nuitsBasseSaison * (1 - occDelta / 100)).round()
          : form.nuitsBasseSaison,
      nuitsHauteSaison: form.mode == RentalMode.courte
          ? (form.nuitsHauteSaison * (1 - occDelta / 100)).round()
          : form.nuitsHauteSaison,
      travaux: form.travaux + travauxDelta,
    );
    final stressCore = computeCore(stressForm);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // Localisation — en premier, avant même les caractéristiques du
        // bien : c'est elle qui détermine les repères de prix/marché.
        const SectionTitle('Localisation'),
        Text("Recherche n'importe quelle commune de France",
            style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.45))),
        const SizedBox(height: 12),
        const CommunePicker(),
        const SizedBox(height: 20),
        // Checklist de visite
        InkWell(
          onTap: () => setState(() => _showVisite = !_showVisite),
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.fact_check_outlined, size: 15, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Checklist de visite',
                      style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
                ]),
                Icon(_showVisite ? Icons.expand_less : Icons.expand_more, color: AppColors.ink.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
        if (_showVisite)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(checklistVisite.length, (i) {
                final checked = _visiteChecked.contains(i);
                return InkWell(
                  onTap: () => setState(() => checked ? _visiteChecked.remove(i) : _visiteChecked.add(i)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: checked ? AppColors.accent : Colors.transparent,
                            border: Border.all(color: checked ? AppColors.accent : AppColors.border),
                          ),
                          child: checked ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            checklistVisite[i],
                            style: AppTextStyles.sans(
                              fontSize: 12.5,
                              color: AppColors.ink.withValues(alpha: checked ? 0.4 : 1),
                              decoration: checked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

        const SectionTitle('Le bien'),
        SyncedTextField(
          value: form.nom,
          onChanged: (v) => set((f) => f.copyWith(nom: v)),
          decoration: InputDecoration(
            hintText: 'Nom du bien — ex. T2 Rue des Lilas',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          ),
          style: AppTextStyles.sans(fontSize: 15, color: AppColors.ink),
        ),
        const SizedBox(height: 12),
        ModeToggle(mode: form.mode, onChanged: (m) => set((f) => f.copyWith(mode: m))),

        Row(children: [
          Expanded(child: NumberField(label: "Prix d'achat", value: form.prix, suffix: '€', onChanged: (v) => set((f) => f.copyWith(prix: v)))),
          const SizedBox(width: 12),
          Expanded(child: NumberField(label: 'Surface', value: form.surface, suffix: 'm²', onChanged: (v) => set((f) => f.copyWith(surface: v)))),
        ]),
        const SizedBox(height: 12),
        Text('Typologie', style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
        const SizedBox(height: 6),
        Row(
          children: typologies.map((t) {
            final active = form.typeBien == t.id;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => set((f) => f.copyWith(typeBien: t.id, capacite: t.capaciteDefaut.toDouble())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: active ? AppColors.accent : AppColors.border),
                    ),
                    child: Text(t.label,
                        style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.ink)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (form.mode == RentalMode.longue) ...[
          const SizedBox(height: 12),
          Text('Location', style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => set((f) => f.copyWith(meuble: false)),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: !form.meuble ? AppColors.accent : Colors.white,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                    border: Border.all(color: !form.meuble ? AppColors.accent : AppColors.border),
                  ),
                  child: Text('Nu', style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: !form.meuble ? Colors.white : AppColors.ink)),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => set((f) => f.copyWith(meuble: true)),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: form.meuble ? AppColors.accent : Colors.white,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                    border: Border.all(color: form.meuble ? AppColors.accent : AppColors.border),
                  ),
                  child: Text('Meublé', style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: form.meuble ? Colors.white : AppColors.ink)),
                ),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              form.meuble
                  ? 'Détermine les régimes fiscaux éligibles (LMNP micro-BIC / réel) dans l\'onglet Fiscalité.'
                  : 'Détermine les régimes fiscaux éligibles (micro-foncier / réel foncier) dans l\'onglet Fiscalité.',
              style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.45)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        NumberField(label: "Capacité d'accueil", value: form.capacite, suffix: 'pers.', hint: 'utile surtout en courte durée', onChanged: (v) => set((f) => f.copyWith(capacite: v))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: NumberField(label: 'Frais de notaire', value: form.notaire, suffix: '€', onChanged: (v) => set((f) => f.copyWith(notaire: v)))),
          const SizedBox(width: 12),
          Expanded(child: NumberField(label: 'Travaux / rénovation', value: form.travaux, suffix: '€', onChanged: (v) => set((f) => f.copyWith(travaux: v)))),
        ]),
        const SizedBox(height: 12),
        Text('Diagnostic de performance énergétique (DPE)', style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
        const SizedBox(height: 6),
        Row(
          children: dpeInfo.keys.map((letter) {
            final info = dpeInfo[letter]!;
            final color = colorFromHex(info.colorHex);
            final active = form.dpe == letter;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => set((f) => f.copyWith(dpe: letter)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? color : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color, width: 1.5),
                      ),
                      child: Text(letter, style: AppTextStyles.sans(fontSize: 14, fontWeight: FontWeight.bold, color: active ? Colors.white : color)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (dpeInfo[form.dpe]?.banIssue != null)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.alert.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.alert)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${dpeInfo[form.dpe]!.banIssue}. Vérifie si des travaux de rénovation énergétique sont nécessaires avant de pouvoir louer.',
                    style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.alert)),
              ),
            ]),
          ),
        const SizedBox(height: 24),

        const SectionTitle('Revenus & charges'),
        if (form.mode == RentalMode.longue) ...[
          Row(children: [
            Expanded(child: NumberField(label: 'Loyer mensuel', value: form.loyer, suffix: '€', onChanged: (v) => set((f) => f.copyWith(loyer: v)))),
            const SizedBox(width: 12),
            Expanded(child: NumberField(label: 'Vacance locative', value: form.vacancePct, suffix: '%', onChanged: (v) => set((f) => f.copyWith(vacancePct: v)))),
          ]),
          if (isNovice) const Tip('La "vacance locative" représente les mois sans locataire entre deux baux. Compte 4 à 8 % par sécurité, même si tu penses louer facilement.'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: NumberField(label: 'Charges copro / an', value: form.chargesCopro, suffix: '€', onChanged: (v) => set((f) => f.copyWith(chargesCopro: v)))),
            const SizedBox(width: 12),
            Expanded(child: NumberField(label: 'Frais de gestion / an', value: form.gestion, suffix: '€', onChanged: (v) => set((f) => f.copyWith(gestion: v)))),
          ]),
        ] else ...[
          Text('Tarifs par saison', style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink.withValues(alpha: 0.6))),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: NumberField(label: 'Prix / nuit — basse saison', value: form.prixNuitBasse, suffix: '€', onChanged: (v) => set((f) => f.copyWith(prixNuitBasse: v)))),
            const SizedBox(width: 12),
            Expanded(child: NumberField(label: 'Nuits occupées — basse saison', value: form.nuitsBasseSaison.toDouble(), suffix: '/an', onChanged: (v) => set((f) => f.copyWith(nuitsBasseSaison: v.round())))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: NumberField(label: 'Prix / nuit — haute saison', value: form.prixNuitHaute, suffix: '€', onChanged: (v) => set((f) => f.copyWith(prixNuitHaute: v)))),
            const SizedBox(width: 12),
            Expanded(child: NumberField(label: 'Nuits occupées — haute saison', value: form.nuitsHauteSaison.toDouble(), suffix: '/an', onChanged: (v) => set((f) => f.copyWith(nuitsHauteSaison: v.round())))),
          ]),
          if (isNovice) const Tip("Découpe l'année en deux périodes types (ex. été/hiver, vacances/reste de l'année) pour un calcul plus réaliste qu'un prix moyen unique."),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statMini('Occupation', '${fmt(core.tauxOccupation, 0)}%', AppColors.accent),
                Container(width: 1, height: 32, color: AppColors.border),
                _statMini('Nuits/an', fmt(core.nuitsTotal, 0), AppColors.ink),
                Container(width: 1, height: 32, color: AppColors.border),
                _statMini('Réservations/an', fmt(core.nombreReservations, 0), AppColors.ink),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Séjours & frais', style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink.withValues(alpha: 0.6))),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: NumberField(label: "Durée moyenne d'un séjour", value: form.dureeSejourMoyenne, suffix: 'nuits', onChanged: (v) => set((f) => f.copyWith(dureeSejourMoyenne: v)))),
            const SizedBox(width: 12),
            Expanded(child: NumberField(label: 'Ménage par réservation', value: form.menagePartReservation, suffix: '€', onChanged: (v) => set((f) => f.copyWith(menagePartReservation: v)))),
          ]),
          if (isNovice) const Tip('Le ménage se paie à chaque changement de voyageur, pas une fois par an — plus les séjours sont courts, plus il y a de ménages à financer.'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: NumberField(label: 'Commission plateforme', value: form.commissionPct, suffix: '%', onChanged: (v) => set((f) => f.copyWith(commissionPct: v)))),
            const SizedBox(width: 12),
            Expanded(child: NumberField(label: 'Renouvellement mobilier/linge', value: form.ameublementAnnuel, suffix: '€/an', onChanged: (v) => set((f) => f.copyWith(ameublementAnnuel: v)))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: NumberField(label: 'Abonnements (élec, internet...)', value: form.abonnements, suffix: '€/an', onChanged: (v) => set((f) => f.copyWith(abonnements: v)))),
            const SizedBox(width: 12),
            Expanded(child: NumberField(label: 'Taxe de séjour', value: form.taxeSejour, suffix: '€/nuit', hint: 'collectée, reversée', onChanged: (v) => set((f) => f.copyWith(taxeSejour: v)))),
          ]),
          if (isNovice) const Tip('La taxe de séjour est payée par le voyageur et reversée à la commune — elle ne rentre ni dans tes revenus ni dans tes charges, c\'est juste un flux à transmettre.'),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: NumberField(label: 'Taxe foncière / an', value: form.taxeFonciere, suffix: '€', onChanged: (v) => set((f) => f.copyWith(taxeFonciere: v)))),
          const SizedBox(width: 12),
          Expanded(child: NumberField(label: 'Assurance PNO / an', value: form.assurance, suffix: '€', onChanged: (v) => set((f) => f.copyWith(assurance: v)))),
        ]),
        const SizedBox(height: 24),

        const SectionTitle('Financement'),
        NumberField(label: 'Apport personnel', value: form.apport, suffix: '€', onChanged: (v) => set((f) => f.copyWith(apport: v))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: NumberField(label: "Taux d'intérêt annuel", value: form.tauxPct, suffix: '%', onChanged: (v) => set((f) => f.copyWith(tauxPct: v)))),
          const SizedBox(width: 12),
          Expanded(child: NumberField(label: 'Durée du prêt', value: form.dureePretAns.toDouble(), suffix: 'ans', onChanged: (v) => set((f) => f.copyWith(dureePretAns: v.round())))),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Expanded(child: _statBlock('Montant emprunté', eur(core.montantEmprunte), AppColors.ink)),
            Expanded(child: _statBlock('Mensualité calculée', eur(core.mensualite), AppColors.accent)),
          ]),
        ),
        const SizedBox(height: 24),

        if (state.niveau == NiveauMode.avance) ...[
          const SectionTitle('Comparer des offres de prêt'),
          ..._buildOffres(state, core),
          const SizedBox(height: 24),
        ],

        const SectionTitle("Capacité d'emprunt"),
        if (isNovice) const Tip("On se base sur la règle des 35 % : la banque accepte rarement que tes mensualités (tous crédits compris) dépassent 35 % de tes revenus nets."),
        Row(children: [
          Expanded(child: NumberField(label: 'Revenus mensuels nets', value: form.revenuMensuelNet, suffix: '€', onChanged: (v) => set((f) => f.copyWith(revenuMensuelNet: v)))),
          const SizedBox(width: 12),
          Expanded(child: NumberField(label: 'Autres crédits en cours', value: form.chargesCreditExistantes, suffix: '€/mois', onChanged: (v) => set((f) => f.copyWith(chargesCreditExistantes: v)))),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: core.capaciteOk ? AppColors.border : AppColors.alert),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Mensualité max (35 % d\'endettement)', style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
              Text(eur(core.mensualiteMax), style: AppTextStyles.mono(fontSize: 15, color: AppColors.ink)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(core.capaciteOk ? Icons.check : Icons.warning_amber_rounded, size: 14, color: core.capaciteOk ? AppColors.accent : AppColors.alert),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  core.capaciteOk ? "Ce projet rentre dans ta capacité d'emprunt" : 'Mensualité au-delà de ta capacité estimée',
                  style: AppTextStyles.sans(fontSize: 12, color: core.capaciteOk ? AppColors.accent : AppColors.alert),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        // ---- Résultats ----
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.ink, AppColors.accent]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.trending_up, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text('RENTABILITÉ NETTE', style: AppTextStyles.sans(fontSize: 11, color: Colors.white70, letterSpacing: 1)),
            ]),
            const SizedBox(height: 10),
            DigitReadout(value: core.net, accent: const Color(0xFFEDE6D2)),
            Container(margin: const EdgeInsets.symmetric(vertical: 14), height: 1, color: Colors.white24),
            Row(children: [
              Expanded(child: _statBlockWhite('Brute', '${fmt(core.brut, 2)}%')),
              Expanded(child: _statBlockWhite('Mensualité', eur(core.mensualite))),
              Expanded(child: _statBlockWhite('Cash-flow /mois', '${core.cashflowMensuel >= 0 ? '+' : ''}${fmt(core.cashflowMensuel)} €',
                  color: core.cashflowMensuel < 0 ? const Color(0xFFE8B4A4) : const Color(0xFFEDE6D2))),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        if (isNovice) VerdictCard(core: core, form: form),

        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.repeat, size: 15, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Longue durée vs courte durée', style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _compareCard('Longue durée', comparaison.longue, comparaison.gagnant == RentalMode.longue)),
              const SizedBox(width: 12),
              Expanded(child: _compareCard('Courte durée', comparaison.courte, comparaison.gagnant == RentalMode.courte)),
            ]),
            const SizedBox(height: 10),
            Text(
              '${comparaison.gagnant == RentalMode.courte ? "La courte durée" : "La longue durée"} ressort environ ${fmt(comparaison.ecartPct.abs(), 0)}% plus rentable ici, à charges et prix identiques — calculé à partir des champs "Revenus & charges" des deux modes ci-dessus.',
              style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
            ),
            if (isNovice) const Tip('La courte durée demande plus de temps de gestion (ménage, accueil, calendrier) — un rendement plus élevé se paie souvent en implication personnelle.'),
          ]),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.bolt, size: 15, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Et si...? (stress-test)', style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
            ]),
            const SizedBox(height: 10),
            _stressRow("Le taux d'emprunt monte de ${fmt(_stressTauxPts, 1)} point${_stressTauxPts > 1 ? 's' : ''}", _stressTaux, () => setState(() => _stressTaux = !_stressTaux)),
            if (_stressTaux)
              _stressAmountField(
                label: 'Points de taux en plus',
                value: _stressTauxPts,
                suffix: 'pt',
                onChanged: (v) => setState(() => _stressTauxPts = v.clamp(0, 10)),
              ),
            _stressRow("L'occupation baisse de ${fmt(_stressOccupationPct, 0)} %", _stressOccupation, () => setState(() => _stressOccupation = !_stressOccupation)),
            if (_stressOccupation)
              _stressAmountField(
                label: "Baisse d'occupation",
                value: _stressOccupationPct,
                suffix: '%',
                onChanged: (v) => setState(() => _stressOccupationPct = v.clamp(0, 100)),
              ),
            _stressRow('+ ${eur(_stressTravauxEuros)} de travaux imprévus', _stressTravaux, () => setState(() => _stressTravaux = !_stressTravaux)),
            if (_stressTravaux)
              _stressAmountField(
                label: 'Travaux imprévus en plus',
                value: _stressTravauxEuros,
                suffix: '€',
                onChanged: (v) => setState(() => _stressTravauxEuros = v.clamp(0, 500000)),
              ),
            if (_anyStress)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.alert.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('RENTABILITÉ NETTE', style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.5))),
                      Text('${fmt(core.net, 1)}% → ${fmt(stressCore.net, 1)}%', style: AppTextStyles.mono(fontSize: 14, color: AppColors.alert)),
                    ]),
                  ),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('CASH-FLOW /MOIS', style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.5))),
                      Text('${fmt(core.cashflowMensuel)}€ → ${fmt(stressCore.cashflowMensuel)}€',
                          style: AppTextStyles.mono(fontSize: 14, color: stressCore.cashflowMensuel < 0 ? AppColors.alert : AppColors.ink)),
                    ]),
                  ),
                ]),
              ),
            if (isNovice) const Tip("Si le bien reste correct même dans ce scénario dégradé, c'est bon signe de solidité. S'il devient très négatif, c'est un risque à connaître avant d'acheter."),
          ]),
        ),

        ElevatedButton.icon(
          onPressed: widget.onSave,
          icon: Icon(context.watch<RendementState>().editingId == null ? Icons.add : Icons.save_outlined),
          label: Text(context.watch<RendementState>().editingId == null ? 'Enregistrer ce bien' : 'Mettre à jour ce bien'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 13, color: AppColors.ink.withValues(alpha: 0.5))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Calculs indicatifs à titre informatif. Consultez un professionnel (notaire, expert-comptable, courtier) avant toute décision d\'investissement.',
              style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _statMini(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.5))),
      const SizedBox(height: 2),
      Text(value, style: AppTextStyles.mono(fontSize: 15, color: color)),
    ]);
  }

  Widget _statBlock(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5))),
      const SizedBox(height: 4),
      Text(value, style: AppTextStyles.mono(fontSize: 16, color: color)),
    ]);
  }

  Widget _statBlockWhite(String label, String value, {Color color = const Color(0xFFEDE6D2)}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AppTextStyles.sans(fontSize: 10, color: Colors.white54)),
      const SizedBox(height: 3),
      Text(value, style: AppTextStyles.mono(fontSize: 15, color: color)),
    ]);
  }

  Widget _compareCard(String label, CoreResult c, bool isWinner) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinner ? AppColors.accent.withValues(alpha: 0.08) : AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isWinner ? AppColors.accent : AppColors.border, width: isWinner ? 1.5 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(label, style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.7)))),
          if (isWinner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(999)),
              child: Text('+ rentable', style: AppTextStyles.sans(fontSize: 9, color: Colors.white)),
            ),
        ]),
        const SizedBox(height: 4),
        DigitReadout(value: c.net, size: ReadoutSize.sm, accent: isWinner ? AppColors.accent : AppColors.ink),
        const SizedBox(height: 4),
        Text('cash-flow ${c.cashflowMensuel >= 0 ? '+' : ''}${fmt(c.cashflowMensuel)} €/mois',
            style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.45))),
      ]),
    );
  }

  Widget _stressRow(String label, bool checked, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: checked ? AppColors.alert : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: checked ? AppColors.alert : AppColors.border, width: 1.5),
            ),
            child: checked ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink))),
        ]),
      ),
    );
  }

  Widget _stressAmountField({
    required String label,
    required double value,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 10),
      child: SizedBox(
        width: 160,
        child: NumberField(label: label, value: value, suffix: suffix, onChanged: onChanged),
      ),
    );
  }

  List<Widget> _buildOffres(RendementState state, CoreResult core) {
    final form = state.form;
    final results = form.offres.map((o) => computeOffre(o, core.montantEmprunte)).toList();
    final minCost = results.isEmpty ? 0.0 : results.map((r) => r.coutTotal).reduce((a, b) => a < b ? a : b);

    final widgets = <Widget>[];
    for (var idx = 0; idx < form.offres.length; idx++) {
      final offre = form.offres[idx];
      final c = results[idx];
      final isBest = form.offres.length > 1 && c.coutTotal == minCost;
      void updateOffre(LoanOffer Function(LoanOffer o) updater) {
        state.updateForm((f) => f.copyWith(
              offres: [for (var i = 0; i < f.offres.length; i++) i == idx ? updater(f.offres[i]) : f.offres[i]],
            ));
      }

      widgets.add(Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isBest ? AppColors.accent : AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: SyncedTextField(
                value: offre.nom,
                onChanged: (v) => updateOffre((o) => o.copyWith(nom: v)),
                style: AppTextStyles.sans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
              ),
            ),
            if (isBest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                child: Text('Moins cher', style: AppTextStyles.sans(fontSize: 10, color: AppColors.accent)),
              ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: NumberField(label: 'Taux', value: offre.tauxPct, suffix: '%', onChanged: (v) => updateOffre((o) => o.copyWith(tauxPct: v)))),
            const SizedBox(width: 8),
            Expanded(child: NumberField(label: 'Durée', value: offre.dureePretAns.toDouble(), suffix: 'ans', onChanged: (v) => updateOffre((o) => o.copyWith(dureePretAns: v.round())))),
            const SizedBox(width: 8),
            Expanded(child: NumberField(label: 'Assurance', value: offre.assurancePct, suffix: '%', onChanged: (v) => updateOffre((o) => o.copyWith(assurancePct: v)))),
          ]),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Mensualité tot. : ', style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))),
              TextSpan(text: eur(c.mensualiteTotale), style: AppTextStyles.mono(fontSize: 12, color: AppColors.ink)),
            ])),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Coût total crédit : ', style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))),
              TextSpan(text: eur(c.coutTotal), style: AppTextStyles.mono(fontSize: 12, color: isBest ? AppColors.accent : AppColors.ink)),
            ])),
          ]),
        ]),
      ));
    }
    if (form.offres.length < 3) {
      widgets.add(OutlinedButton(
        onPressed: () => state.updateForm((f) => f.copyWith(offres: [
              ...f.offres,
              LoanOffer(
                id: DateTime.now().millisecondsSinceEpoch,
                nom: 'Banque ${String.fromCharCode(65 + f.offres.length)}',
                tauxPct: 3.8,
                dureePretAns: 20,
                assurancePct: 0.3,
              ),
            ])),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: BorderSide(color: AppColors.border, style: BorderStyle.solid),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text('+ Ajouter une offre'),
      ));
    }
    return widgets;
  }
}
