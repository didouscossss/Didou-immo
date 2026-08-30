import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import 'patrimoine_screen.dart';
import 'projection_screen.dart';

enum _Tab { calc, marche, carte, fisc, proj, biens, patrimoine }

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
    (tab: _Tab.patrimoine, label: 'Patrimoine', icon: Icons.insights_outlined),
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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: AppColors.backgroundGradient),
        ),
        child: SafeArea(
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
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Rendement', style: AppTextStyles.serif(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
                              Text("Calculez avant d'investir", style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.45))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // FittedBox : sur téléphone, les 3 icônes + le sélecteur
                        // Novice/Avancé ne tenaient plus sur la largeur depuis
                        // l'ajout du bouton mode nuit — "Avancé" se retrouvait
                        // coupé hors écran. On rétrécit l'ensemble plutôt que
                        // de le laisser déborder.
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(children: [
                              InkWell(
                                onTap: state.toggleDarkMode,
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                                  child: Icon(state.darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 15, color: AppColors.ink),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _openAccount,
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                                  child: Icon(Icons.person_outline, size: 15, color: AppColors.ink),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => setState(() => _showMethodo = true),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                                  child: Icon(Icons.help_outline, size: 15, color: AppColors.ink),
                                ),
                              ),
                              const SizedBox(width: 8),
                              NiveauToggle(niveau: state.niveau, onChanged: state.setNiveau),
                            ]),
                          ),
                        ),
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
      ),
    );
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

  // Chaque écran est reconstruit entièrement (clé sur darkMode + niveau,
  // les deux pilotant AppColors) à chaque changement de l'un ou l'autre :
  // certains widgets internes sont déclarés `const` (ex. `SectionTitle`),
  // donc Flutter réutilise la même instance et ne relit jamais
  // `AppColors.xxx` tant que la branche n'est pas démontée — sans la clé,
  // les libellés/fonds restaient figés dans l'ancienne couleur jusqu'à
  // changer d'onglet puis revenir.
  Widget _buildActiveScreen(RendementState state) {
    final themeKey = ValueKey((state.darkMode, state.niveau));
    switch (_active) {
      case _Tab.calc:
        return CalcScreen(key: themeKey, onSave: () => _handleSave(state));
      case _Tab.marche:
        return MarcheScreen(key: themeKey, onGoToBien: () => setState(() => _active = _Tab.calc));
      case _Tab.carte:
        return CarteScreen(key: themeKey);
      case _Tab.fisc:
        return FiscaliteScreen(key: themeKey);
      case _Tab.proj:
        return ProjectionScreen(key: themeKey);
      case _Tab.biens:
        return BiensScreen(key: themeKey, onEdit: () => setState(() => _active = _Tab.calc));
      case _Tab.patrimoine:
        return PatrimoineScreen(key: themeKey);
    }
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _tabs.map((t) {
          final active = _active == t.tab;
          final color = active ? AppColors.accent : AppColors.ink.withValues(alpha: 0.62);
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
