import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_tab.dart';
import '../../state/rendement_state.dart';
import '../../state/user_account_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/niveau_toggle.dart';
import '../account/account_screen.dart';
import '../paywall/paywall_screen.dart';
import 'app_tab_meta.dart';
import 'biens_screen.dart';
import 'calc_screen.dart';
import 'carte_screen.dart';
import 'fiscalite_screen.dart';
import 'marche_screen.dart';
import 'methodologie_sheet.dart';
import 'onboarding_sheet.dart';
import 'patrimoine_screen.dart';
import 'projection_screen.dart';
import 'tab_customization_screen.dart';

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
  AppTab _active = AppTab.calc;
  bool _showMethodo = false;
  late final PageController _pageController;
  List<AppTab>? _lastVisibleTabs;

  @override
  void initState() {
    super.initState();
    final tabs = context.read<RendementState>().visibleTabOrder;
    _pageController = PageController(initialPage: tabs.indexOf(_active).clamp(0, tabs.length - 1));
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<RendementState>().load());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Change d'onglet — utilisé par la barre du bas et par la navigation
  /// interne (ex. après avoir enregistré un bien). Anime le `PageView` vers
  /// la bonne page plutôt que de simplement changer `_active` : c'est ce
  /// `PageView` qui fait maintenant réellement défiler l'écran affiché.
  void _setActive(AppTab tab, {bool animate = true}) {
    if (!mounted) return;
    final index = context.read<RendementState>().visibleTabOrder.indexOf(tab);
    if (index == -1) return;
    setState(() => _active = tab);
    if (!_pageController.hasClients) return;
    if (animate) {
      _pageController.animateToPage(index, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    } else {
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    // Si l'onglet actif vient d'être masqué depuis "Personnaliser mon
    // affichage", on retombe sur le premier onglet encore visible plutôt
    // que de rendre un écran caché — sans toucher à `_active` lui-même
    // pendant ce build (setState pendant build), pour qu'il redevienne actif
    // tel quel si l'utilisateur le réaffiche ensuite.
    final visibleTabs = state.visibleTabOrder;
    final active = visibleTabs.contains(_active) ? _active : visibleTabs.first;
    // Un simple réordonnancement (sans masquer l'onglet actif) laisse
    // `active` inchangé mais décale sa POSITION dans la liste — sans ce
    // repositionnement, le `PageView` resterait sur son ancien index
    // physique et afficherait le mauvais onglet après un aller-retour sur
    // "Personnaliser mon affichage".
    if (!listEquals(_lastVisibleTabs, visibleTabs)) {
      _lastVisibleTabs = visibleTabs;
      WidgetsBinding.instance.addPostFrameCallback((_) => _setActive(active, animate: false));
    }

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
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TabCustomizationScreen())),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                                  child: Icon(Icons.dashboard_customize_outlined, size: 15, color: AppColors.ink),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: visibleTabs.length,
                      // Bloque le swipe sur l'onglet Carte : FlutterMap capte déjà
                      // le glissement horizontal pour déplacer la carte, un swipe
                      // de page par-dessus ferait les deux à la fois. Les autres
                      // onglets restent swipables normalement ; un tap sur la
                      // barre du bas continue de fonctionner partout.
                      physics: active == AppTab.carte ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
                      onPageChanged: (i) => setState(() => _active = visibleTabs[i]),
                      itemBuilder: (context, i) => _buildActiveScreen(state, visibleTabs[i]),
                    ),
                  ),
                  _buildTabBar(state, visibleTabs, active),
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
    // seule la création d'un NOUVEAU bien compte, identifiée par
    // `editingId` encore nul à cet instant (`saveCurrentProperty` le fait
    // ensuite pointer vers le bien créé, pour que tout enregistrement
    // suivant sur ce même brouillon soit traité comme une mise à jour).
    final isNewProperty = state.editingId == null;
    if (!widget.firebaseReady) {
      await state.saveCurrentProperty();
      if (!mounted) return;
      _setActive(AppTab.biens);
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
    _setActive(AppTab.biens);
  }

  // Chaque écran est reconstruit entièrement (clé sur darkMode + niveau,
  // les deux pilotant AppColors) à chaque changement de l'un ou l'autre :
  // certains widgets internes sont déclarés `const` (ex. `SectionTitle`),
  // donc Flutter réutilise la même instance et ne relit jamais
  // `AppColors.xxx` tant que la branche n'est pas démontée — sans la clé,
  // les libellés/fonds restaient figés dans l'ancienne couleur jusqu'à
  // changer d'onglet puis revenir.
  Widget _buildActiveScreen(RendementState state, AppTab active) {
    final themeKey = ValueKey((state.darkMode, state.niveau));
    switch (active) {
      case AppTab.calc:
        return CalcScreen(key: themeKey, onSave: () => _handleSave(state));
      case AppTab.marche:
        return MarcheScreen(key: themeKey, onGoToBien: () => _setActive(AppTab.calc));
      case AppTab.carte:
        return CarteScreen(key: themeKey);
      case AppTab.fisc:
        return FiscaliteScreen(key: themeKey);
      case AppTab.proj:
        return ProjectionScreen(key: themeKey);
      case AppTab.biens:
        return BiensScreen(key: themeKey, onEdit: () => _setActive(AppTab.calc));
      case AppTab.patrimoine:
        return PatrimoineScreen(key: themeKey);
    }
  }

  Widget _buildTabBar(RendementState state, List<AppTab> visibleTabs, AppTab active) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: visibleTabs.map((t) {
          final meta = kTabMeta[t]!;
          final isActive = active == t;
          final color = isActive ? AppColors.accent : AppColors.ink.withValues(alpha: 0.62);
          return InkWell(
            onTap: () => _setActive(t),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(meta.icon, size: 18, color: color),
                const SizedBox(height: 3),
                Text(meta.label, style: AppTextStyles.sans(fontSize: 9, fontWeight: FontWeight.w500, color: color)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}
