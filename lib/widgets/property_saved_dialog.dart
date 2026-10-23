import 'package:flutter/material.dart';

import '../state/rendement_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/improvement_suggestions.dart';
import 'digit_readout.dart';
import 'score_badge.dart';

/// Pop-up affiché juste après l'enregistrement (ou la mise à jour) d'un
/// bien — demandé par l'utilisateur : avant, "Enregistrer" faisait
/// basculer directement sur l'onglet "Comparer" sans jamais montrer la
/// rentabilité qui vient d'être calculée, obligeant à rouvrir le bien pour
/// la voir. Affiche les chiffres clés tout de suite, où les retrouver
/// ensuite, et jusqu'à 2 pistes concrètes (chiffrées, pas inventées — voir
/// `computeImprovementSuggestions`) pour améliorer la rentabilité ou le
/// cash-flow — avant de laisser `RendementHome` basculer sur "Comparer"
/// comme avant.
Future<void> showPropertySavedDialog(
  BuildContext context, {
  required RendementState state,
  required bool isNewProperty,
}) {
  final form = state.form;
  final core = state.core;
  final score = state.score;
  final suggestions = computeImprovementSuggestions(form, core);
  final scoreColor = colorFromHex(score.colorHex);
  // `revenuMensuelNet` vaut 0 tant que l'utilisateur n'a pas renseigné ce
  // champ ("Financement") — afficher la capacité d'emprunt dans ce cas la
  // signalerait systématiquement comme insuffisante, à tort.
  final showCapacite = form.revenuMensuelNet > 0;

  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(Icons.check_circle, color: AppColors.good, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isNewProperty ? 'Bien enregistré !' : 'Bien mis à jour !',
                  style: AppTextStyles.serif(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              form.nom.isEmpty ? 'Bien sans nom' : form.nom,
              style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.trending_up, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text('RENTABILITÉ NETTE', style: AppTextStyles.sans(fontSize: 11, color: Colors.white70, letterSpacing: 1.2)),
                ]),
                const SizedBox(height: 10),
                DigitReadout(value: core.net, accent: const Color(0xFFEDE6D2)),
                Container(margin: const EdgeInsets.symmetric(vertical: 16), height: 1, color: Colors.white24),
                Row(children: [
                  Expanded(child: _stat('Brute', '${fmt(core.brut, 2)}%')),
                  const SizedBox(width: 14),
                  Expanded(child: _stat('Mensualité', eur(core.mensualite))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _stat(
                      'Cash-flow /mois',
                      '${core.cashflowMensuel >= 0 ? '+' : ''}${fmt(core.cashflowMensuel)} €',
                      color: core.cashflowMensuel < 0 ? const Color(0xFFE8B4A4) : const Color(0xFFEDE6D2),
                    ),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Expanded(child: _miniStat('Apport', eur(core.apport))),
                const SizedBox(width: 14),
                Expanded(child: _miniStat('Emprunté', eur(core.montantEmprunte))),
                const SizedBox(width: 14),
                Expanded(child: _miniStat('Prix au m²', '${fmt(core.prixM2)} €')),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              ScoreBadge(score: score.score, label: score.label, color: scoreColor, size: BadgeSize.sm),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    "Score d'investissement",
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
                  ),
                  Text(score.label, overflow: TextOverflow.ellipsis, style: AppTextStyles.sans(fontSize: 11, color: scoreColor)),
                ]),
              ),
            ]),
            if (showCapacite) ...[
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(
                  core.capaciteOk ? Icons.check_circle_outline : Icons.error_outline,
                  size: 15,
                  color: core.capaciteOk ? AppColors.good : AppColors.alert,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    core.capaciteOk
                        ? "Capacité d'emprunt confortable (mensualité ≤ ${eur(core.mensualiteMax.round())} recommandés)."
                        : "Mensualité au-dessus de ta capacité d'emprunt recommandée (max ${eur(core.mensualiteMax.round())}).",
                    style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.7)).copyWith(height: 1.4),
                  ),
                ),
              ]),
            ],
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(children: [
                Icon(Icons.lightbulb_outline, size: 15, color: AppColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pistes pour améliorer la rentabilité',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              for (var i = 0; i < suggestions.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _suggestionCard(suggestions[i]),
              ],
            ],
            const SizedBox(height: 18),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.ink.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Retrouve ce bien et sa rentabilité à tout moment dans l'onglet Comparer.",
                  style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6)).copyWith(height: 1.4),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Voir mes biens'),
            ),
          ]),
        ),
      ),
    ),
  );
}

Widget _stat(String label, String value, {Color color = const Color(0xFFEDE6D2)}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label.toUpperCase(), style: AppTextStyles.sans(fontSize: 10, color: Colors.white54, letterSpacing: 0.4)),
    const SizedBox(height: 5),
    Text(value, style: AppTextStyles.mono(fontSize: 15, color: color, letterSpacing: 0.3)),
  ]);
}

Widget _miniStat(String label, String value) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label.toUpperCase(), style: AppTextStyles.sans(fontSize: 9.5, color: AppColors.ink.withValues(alpha: 0.45), letterSpacing: 0.4)),
    const SizedBox(height: 5),
    Text(value, style: AppTextStyles.mono(fontSize: 13, color: AppColors.ink, letterSpacing: 0.3)),
  ]);
}

Widget _suggestionCard(ImprovementSuggestion s) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.gold.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.title, style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
      const SizedBox(height: 5),
      Text(
        s.description,
        style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.75)).copyWith(height: 1.45),
      ),
    ]),
  );
}
