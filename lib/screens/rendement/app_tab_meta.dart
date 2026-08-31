import 'package:flutter/material.dart';

import '../../models/app_tab.dart';

/// Libellé + icône affichés pour chaque onglet — regroupés ici (plutôt que
/// dispersés dans `RendementHome`) pour que l'écran "Personnaliser mon
/// affichage" puisse les réutiliser tels quels.
class AppTabMeta {
  final String label;
  final IconData icon;
  const AppTabMeta(this.label, this.icon);
}

const Map<AppTab, AppTabMeta> kTabMeta = {
  AppTab.calc: AppTabMeta('Bien', Icons.home_outlined),
  AppTab.marche: AppTabMeta('Marché', Icons.location_on_outlined),
  AppTab.carte: AppTabMeta('Carte', Icons.map_outlined),
  AppTab.fisc: AppTabMeta('Fiscalité', Icons.account_balance_outlined),
  AppTab.proj: AppTabMeta('Projection', Icons.trending_up),
  AppTab.biens: AppTabMeta('Comparer', Icons.layers_outlined),
  AppTab.patrimoine: AppTabMeta('Patrimoine', Icons.insights_outlined),
};
