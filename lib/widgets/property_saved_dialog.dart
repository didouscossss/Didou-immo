import 'package:flutter/material.dart';

import '../state/rendement_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'digit_readout.dart';

/// Pop-up affiché juste après l'enregistrement (ou la mise à jour) d'un
/// bien — demandé par l'utilisateur : avant, "Enregistrer" faisait
/// basculer directement sur l'onglet "Comparer" sans jamais montrer la
/// rentabilité qui vient d'être calculée, obligeant à rouvrir le bien pour
/// la voir. Affiche les chiffres clés tout de suite, et rappelle où les
/// retrouver ensuite — avant de laisser `RendementHome` basculer sur
/// "Comparer" comme avant.
Future<void> showPropertySavedDialog(
  BuildContext context, {
  required RendementState state,
  required bool isNewProperty,
}) {
  final form = state.form;
  final core = state.core;
  final score = state.score;
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
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
          const SizedBox(height: 4),
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
                Text('RENTABILITÉ NETTE', style: AppTextStyles.sans(fontSize: 11, color: Colors.white70, letterSpacing: 1)),
              ]),
              const SizedBox(height: 10),
              DigitReadout(value: core.net, accent: const Color(0xFFEDE6D2)),
              Container(margin: const EdgeInsets.symmetric(vertical: 14), height: 1, color: Colors.white24),
              Row(children: [
                Expanded(child: _stat('Brute', '${fmt(core.brut, 2)}%')),
                Expanded(child: _stat('Mensualité', eur(core.mensualite))),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Expanded(child: _miniStat('Apport', eur(core.apport))),
              Expanded(child: _miniStat('Emprunté', eur(core.montantEmprunte))),
              Expanded(child: _miniStat('Score', '${score.score}/100')),
            ]),
          ),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, size: 14, color: AppColors.ink.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Retrouve ce bien et sa rentabilité à tout moment dans l'onglet Comparer.",
                style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6)),
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
  );
}

Widget _stat(String label, String value, {Color color = const Color(0xFFEDE6D2)}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label.toUpperCase(), style: AppTextStyles.sans(fontSize: 10, color: Colors.white54)),
    const SizedBox(height: 3),
    Text(value, style: AppTextStyles.mono(fontSize: 15, color: color)),
  ]);
}

Widget _miniStat(String label, String value) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label.toUpperCase(), style: AppTextStyles.sans(fontSize: 9.5, color: AppColors.ink.withValues(alpha: 0.45))),
    const SizedBox(height: 3),
    Text(value, style: AppTextStyles.mono(fontSize: 13, color: AppColors.ink)),
  ]);
}
