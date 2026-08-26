import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/niveau_toggle.dart';
import 'biens_screen.dart';
import 'calc_screen.dart';
import 'fiscalite_screen.dart';
import 'marche_screen.dart';
import 'methodologie_sheet.dart';
import 'onboarding_sheet.dart';
import 'projection_screen.dart';

enum _Tab { calc, marche, fisc, proj, biens }

/// Coquille de l'app — équivalent du composant `RendementApp` (barre du
/// haut + navigation par onglets + overlays onboarding/méthodologie).
class RendementHome extends StatefulWidget {
  const RendementHome({super.key});

  @override
  State<RendementHome> createState() => _RendementHomeState();
}

class _RendementHomeState extends State<RendementHome> {
  _Tab _active = _Tab.calc;
  bool _showMethodo = false;

  static const _tabs = [
    (tab: _Tab.calc, label: 'Bien', icon: Icons.home_outlined),
    (tab: _Tab.marche, label: 'Marché', icon: Icons.location_on_outlined),
    (tab: _Tab.fisc, label: 'Fiscalité', icon: Icons.account_balance_outlined),
    (tab: _Tab.proj, label: 'Projection', icon: Icons.trending_up),
    (tab: _Tab.biens, label: 'Comparer', icon: Icons.layers_outlined),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<RendementState>().load());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rendement', style: AppTextStyles.serif(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          Text("Calculez avant d'investir", style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.45))),
                        ],
                      ),
                      Row(children: [
                        InkWell(
                          onTap: () => setState(() => _showMethodo = true),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                            child: const Icon(Icons.help_outline, size: 15, color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(width: 8),
                        NiveauToggle(niveau: state.niveau, onChanged: state.setNiveau),
                      ]),
                    ],
                  ),
                ),
                Expanded(child: _buildActiveScreen(state)),
                _buildTabBar(),
              ],
            ),
            if (!state.loaded) const SizedBox.shrink(),
            if (state.loaded && state.showOnboarding)
              OnboardingSheet(
                onFinish: (mode, budget) => state.finishOnboarding(mode: mode, budget: budget),
              ),
            if (_showMethodo) MethodologieSheet(onClose: () => setState(() => _showMethodo = false)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveScreen(RendementState state) {
    switch (_active) {
      case _Tab.calc:
        return CalcScreen(onSave: () {
          state.saveCurrentProperty();
          setState(() => _active = _Tab.biens);
        });
      case _Tab.marche:
        return const MarcheScreen();
      case _Tab.fisc:
        return const FiscaliteScreen();
      case _Tab.proj:
        return const ProjectionScreen();
      case _Tab.biens:
        return const BiensScreen();
    }
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _tabs.map((t) {
          final active = _active == t.tab;
          final color = active ? AppColors.accent : AppColors.ink.withValues(alpha: 0.35);
          return InkWell(
            onTap: () => setState(() => _active = t.tab),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(t.icon, size: 18, color: color),
                const SizedBox(height: 3),
                Text(t.label, style: AppTextStyles.sans(fontSize: 9, fontWeight: FontWeight.w500, color: color)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}
