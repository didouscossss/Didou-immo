import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculations.dart';
import '../../utils/formatters.dart';
import '../../widgets/section_title.dart';
import '../../widgets/tip.dart';

/// Onglet "Marché" — équivalent de `MarcheScreen` du prototype. La
/// localisation elle-même se saisit désormais dans l'onglet "Bien" (voir
/// `CommunePicker`) ; cet écran affiche les repères de prix qui en découlent.
class MarcheScreen extends StatelessWidget {
  /// Bascule vers l'onglet "Bien" pour saisir la localisation — appelé quand
  /// aucune commune n'est encore choisie.
  final VoidCallback onGoToBien;
  const MarcheScreen({super.key, required this.onGoToBien});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    final form = state.form;
    final core = state.core;
    final refInfo = state.refInfoAjuste;
    final refs = state.refs;
    final typology = state.typology;
    final score = state.score;
    final isNovice = state.niveau == NiveauMode.novice;
    final commune = form.commune;
    final ref = refInfo?.ref;
    final live = state.liveMarketPrice;
    // Prix réel (VALORIS/DVF) si disponible pour cette commune, sinon
    // repère indicatif statique — le loyer, lui, reste toujours indicatif
    // (DVF ne couvre que les ventes, pas les locations).
    final prixEffectif = live?.prixMedianM2 ?? ref?.prixM2;

    final ecartPrix = (prixEffectif != null && prixEffectif > 0 && core.prixM2 > 0)
        ? ((core.prixM2 - prixEffectif) / prixEffectif) * 100
        : null;
    final ecartLoyer = (ref != null && core.loyerM2 > 0) ? ((core.loyerM2 - ref.loyerM2) / ref.loyerM2) * 100 : null;

    final loyerDonneeCommune = refInfo?.loyerDonneeCommune == true;
    final loyerLabel = loyerDonneeCommune ? 'Loyer estimé / m² (annonces)' : 'Loyer repère / m²';
    // "Carte des loyers" (Ministère chargé du Logement / ANIL) : ce sont des
    // loyers D'ANNONCE modélisés à partir des annonces LeBonCoin/SeLoger, pas
    // des baux réellement signés comme DVF l'est pour le prix — d'où la
    // distinction commune directe / zone élargie, à ne pas présenter comme
    // une vérité absolue.
    final loyerCaption = !loyerDonneeCommune
        ? null
        : refInfo?.loyerEstimationZone == true
            ? "Pas assez d'annonces observées à ${commune?.nom} : estimation basée sur sa zone statistique élargie."
                ' Estimations ANIL, d\'après des données du groupe SeLoger et de leboncoin (édition 2025).'
            : 'Estimation directe pour ${commune?.nom}, à partir des annonces de location du secteur.'
                ' Estimations ANIL, d\'après des données du groupe SeLoger et de leboncoin (édition 2025).';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SectionTitle('Localisation & marché'),
        Text('Repères de prix pour la commune du bien',
            style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.45))),
        const SizedBox(height: 12),
        if (commune == null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Aucune commune renseignée', style: AppTextStyles.sans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text('La localisation se saisit dans l\'onglet "Bien", avec le reste des caractéristiques.',
                  style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.5))),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onGoToBien,
                icon: const Icon(Icons.arrow_back, size: 15),
                label: const Text('Renseigner la localisation'),
              ),
            ]),
          ),
        if (commune != null) ...[
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 4, children: [
            Icon(Icons.location_on_outlined, size: 14, color: AppColors.accent),
            Text(commune.nom, style: AppTextStyles.sans(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
            Text(commune.departement, style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.45))),
            if (ref?.tension == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.alert.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                child: Text('Zone tendue possible', style: AppTextStyles.sans(fontSize: 10, color: AppColors.alert)),
              ),
          ]),
          if (isVilleEncadrementLoyers(commune.nom))
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.alert.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.alert)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${commune.nom} applique l'encadrement des loyers : un plafond légal limite le loyer au m² selon le quartier et le type de logement. Vérifie le plafond applicable sur service-public.fr avant de fixer ton loyer — le dépasser expose à une amende et à devoir rembourser le trop-perçu.",
                    style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.alert),
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _statCard(
                state.loadingLiveMarketPrice ? 'Prix / m² (chargement...)' : (live != null ? 'Prix réel / m² (DVF)' : 'Prix repère / m²'),
                eur(prixEffectif),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _statCard(loyerLabel, eur(ref?.loyerM2))),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              (live != null
                      ? 'Prix médian réel sur ${live.nbTransactions} vente${live.nbTransactions > 1 ? 's' : ''} (${live.annee})'
                          '${live.evolution1AnPct != null ? ', ${live.evolution1AnPct! > 0 ? '+' : ''}${live.evolution1AnPct!.toStringAsFixed(1)}% sur 1 an' : ''}'
                          ' — source VALORIS / DVF, Licence Ouverte (Etalab).'
                      : refInfo?.precise == true
                          ? 'Prix rattaché directement à ${ref!.name} (repère indicatif).'
                          : "Pas de moyenne fiable pour une commune de cette taille — prix basé sur ${ref?.name == 'Moyenne nationale' ? 'la moyenne nationale' : '${ref?.name}, la référence la plus proche'}. À vérifier avec un notaire local.") +
                  (form.mode == RentalMode.longue && form.meuble
                      ? ' Loyer repère majoré de ${((primeMeuble - 1) * 100).round()}% (meublé).'
                      : ''),
              style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.45)),
            ),
          ),
          if (loyerCaption != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(loyerCaption, style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.45))),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ton bien vs le repère', style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
              const SizedBox(height: 10),
              if (form.surface > 0) ...[
                _ecartRow('Prix/m² du bien : ${eur(core.prixM2)}', ecartPrix, invert: false),
                const SizedBox(height: 6),
                _ecartRow('Loyer/m² du bien : ${eur(core.loyerM2)}', ecartLoyer, invert: true),
              ] else
                Text('Renseigne la surface du bien dans l\'onglet "Bien" pour comparer.',
                    style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.45))),
            ]),
          ),
          if (refs != null && form.surface > 0)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text('Repère par typologie — ${typology.label}', style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink))),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.people_outline, size: 11, color: AppColors.ink.withValues(alpha: 0.45)),
                    const SizedBox(width: 3),
                    Text('${fmt(form.capacite, 0)} pers. max', style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.45))),
                  ]),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(8)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('LOYER REPÈRE (LONGUE)', style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.65))),
                        Text('${eur(refs.loyerMensuelRef)}/mois', style: AppTextStyles.mono(fontSize: 15, color: AppColors.ink)),
                        if (form.mode == RentalMode.longue)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('ton loyer : ${eur(form.loyer)}',
                                style: AppTextStyles.mono(fontSize: 10.5, color: form.loyer <= refs.loyerMensuelRef ? AppColors.accent : AppColors.alert)),
                          ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(8)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('NUITÉE REPÈRE (COURTE)', style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.65))),
                        Text('${eur(refs.nuiteeRef)}/nuit', style: AppTextStyles.mono(fontSize: 15, color: AppColors.ink)),
                        if (form.mode == RentalMode.courte && (core.prixNuitMoyen ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('ta nuitée moy. : ${eur(core.prixNuitMoyen)}',
                                style: AppTextStyles.mono(fontSize: 10.5, color: (core.prixNuitMoyen ?? 0) <= refs.nuiteeRef ? AppColors.accent : AppColors.alert)),
                          ),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  'Repères ajustés selon la typologie (${typology.label}, coefficient indicatif) et la capacité d\'accueil déclarée — pas de moyenne réelle par village pour la courte durée, à confronter aux annonces comparables sur place.',
                  style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.45)),
                ),
              ]),
            ),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
                child: Text('${score.score}', style: AppTextStyles.mono(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Score d'investissement", style: AppTextStyles.sans(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
                  Text('${score.label} · basé sur rendement, cash-flow, prix marché, occupation',
                      style: AppTextStyles.sans(fontSize: 12, color: Colors.white70)),
                ]),
              ),
            ]),
            if (!isNovice) ...[
              Container(margin: const EdgeInsets.symmetric(vertical: 14), height: 1, color: Colors.white24),
              _scorePartRow('Rendement', score.parts.rendement, 40),
              _scorePartRow('Cash-flow', score.parts.cashflow, 25),
              _scorePartRow('Prix vs marché', score.parts.marche, 20),
              _scorePartRow('Occupation', score.parts.occupation, 15),
            ],
          ]),
        ),
        if (isNovice) const Tip("Un score au-dessus de 60 est généralement un bon signal. En dessous de 40, ce bien mérite d'être comparé avec d'autres avant de te décider."),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 13, color: AppColors.ink.withValues(alpha: 0.5))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Repères de prix indicatifs et arrondis — vérifie les données locales réelles (notaires, observatoires des loyers) avant de décider.',
              style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.65))),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.mono(fontSize: 17, color: AppColors.ink)),
      ]),
    );
  }

  Widget _ecartRow(String label, double? ecart, {required bool invert}) {
    final positive = invert ? (ecart ?? 0) >= 0 : (ecart ?? 0) <= 0;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: Text(label, style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.7)))),
      if (ecart != null)
        Text('${ecart > 0 ? '+' : ''}${fmt(ecart, 1)}%', style: AppTextStyles.mono(fontSize: 12.5, color: positive ? AppColors.accent : AppColors.alert)),
    ]);
  }

  Widget _scorePartRow(String label, double value, double max) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 90, child: Text(label, style: AppTextStyles.sans(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.7)))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (value / max).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(AppColors.gold),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text('${fmt(value, 0)}/${fmt(max, 0)}',
              textAlign: TextAlign.right,
              style: AppTextStyles.mono(fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
        ),
      ]),
    );
  }
}
