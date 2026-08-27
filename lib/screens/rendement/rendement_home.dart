import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/pdf_export_service.dart';
import '../../state/rendement_state.dart';
import '../../state/user_account_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/niveau_toggle.dart';
import '../account/account_screen.dart';
import '../paywall/paywall_screen.dart';
import 'biens_screen.dart';
import 'calc_screen.dart';
import 'carte_screen.dart';
import 'fiscalite_screen.dart';
import 'marche_screen.dart';
import 'methodologie_sheet.dart';
import 'onboarding_sheet.dart';
import 'projection_screen.dart';

enum _Tab { calc, marche, carte, fisc, proj, biens }

/// Coquille de l'app — équivalent du composant `RendementApp` (barre du
/// haut + navigation par onglets + overlays onboarding/méthodologie).
///
/// [firebaseReady] indique si un compte est réellement disponible (voir
/// `main.dart`) : à `false`, l'app tourne en mode local — enregistrement de
/// biens illimité sur l'appareil, comme avant l'ajout des comptes.
class RendementHome extends StatefulWidget {
  final bool firebaseReady;
  const RendementHome({super.key, required this.firebaseReady});

  @override
  State<RendementHome> createState() => _RendementHomeState();
}

class _RendementHomeState extends State<RendementHome> {
  _Tab _active = _Tab.calc;
  bool _showMethodo = false;

  static const _tabs = [
    (tab: _Tab.calc, label: 'Bien', icon: Icons.home_outlined),
    (tab: _Tab.marche, label: 'Marché', icon: Icons.location_on_outlined),
    (tab: _Tab.carte, label: 'Carte', icon: Icons.map_outlined),
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
                          onTap: () => _exportPdf(state),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                            child: const Icon(Icons.picture_as_pdf_outlined, size: 15, color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _openAccount,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                            child: const Icon(Icons.person_outline, size: 15, color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(width: 8),
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

  /// Exporte le bien actuellement à l'étude en PDF (chiffres clés, régimes
  /// fiscaux, tableau d'amortissement) — ouvre l'aperçu natif d'impression
  /// / partage / enregistrement, disponible aussi bien sur le web
  /// (téléchargement) que sur Android (feuille de partage).
  Future<void> _exportPdf(RendementState state) async {
    try {
      await PdfExportService.exportBien(
        form: state.form,
        core: state.core,
        regimes: state.regimes,
        amortissement: state.amortissement,
        score: state.score,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'export PDF, réessaie dans un instant.")),
      );
    }
  }

  void _openAccount() {
    if (!widget.firebaseReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte bientôt disponible sur cette version.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen()));
  }

  /// Enregistre le bien courant — en mode local (pas de compte), c'est
  /// toujours possible ; une fois connecté, ça compte comme un essai
  /// gratuit et bascule sur le paywall au-delà de la limite.
  ///
  /// On attend la fin de l'écriture avant de changer d'onglet : sans ça,
  /// une écriture Firestore qui échoue (réseau, règles) passait inaperçue —
  /// l'écran basculait sur "Mes projets" alors que rien n'avait été
  /// enregistré.
  Future<void> _handleSave(RendementState state) async {
    // Modifier un bien déjà enregistré (voir `loadPropertyForEditing`) ne
    // doit ni consommer un essai gratuit, ni être bloqué par le paywall —
    // seule la création d'un NOUVEAU bien compte. `saveCurrentProperty`
    // remet `editingId` à null une fois l'enregistrement fait, donc on
    // capture cette info avant de l'appeler.
    final isNewProperty = state.editingId == null;
    if (!widget.firebaseReady) {
      await state.saveCurrentProperty();
      if (!mounted) return;
      setState(() => _active = _Tab.biens);
      return;
    }
    final account = context.read<UserAccountState>();
    if (isNewProperty && !account.canSaveForFree) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      return;
    }
    try {
      await state.saveCurrentProperty();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Échec de l'enregistrement, vérifie ta connexion et réessaie."),
        ),
      );
      return;
    }
    if (isNewProperty) await account.recordFreeSave();
    if (!mounted) return;
    setState(() => _active = _Tab.biens);
  }

  Widget _buildActiveScreen(RendementState state) {
    switch (_active) {
      case _Tab.calc:
        return CalcScreen(onSave: () => _handleSave(state));
      case _Tab.marche:
        return MarcheScreen(onGoToBien: () => setState(() => _active = _Tab.calc));
      case _Tab.carte:
        return const CarteScreen();
      case _Tab.fisc:
        return const FiscaliteScreen();
      case _Tab.proj:
        return const ProjectionScreen();
      case _Tab.biens:
        return BiensScreen(onEdit: () => setState(() => _active = _Tab.calc));
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
