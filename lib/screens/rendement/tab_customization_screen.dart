import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_tab.dart';
import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';
import 'app_tab_meta.dart';

/// "Personnaliser mon affichage" — réordonne (glisser via la poignée) et
/// masque/affiche les onglets principaux de l'app. [RendementState.tabOrder]
/// garde toujours les 7 onglets (masqué ou non), pour ne jamais perdre la
/// position d'un onglet qu'on masque puis réaffiche plus tard.
class TabCustomizationScreen extends StatelessWidget {
  const TabCustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    final order = state.tabOrder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personnaliser mon affichage'),
        actions: [
          TextButton(
            onPressed: state.resetTabLayout,
            child: Text('Réinitialiser', style: AppTextStyles.sans(fontSize: 13, color: AppColors.accent)),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            'Fais glisser la poignée pour réordonner tes onglets, ou masque ceux dont tu ne te sers pas — '
            'au moins un onglet doit rester affiché.',
            style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.6)),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: order.length,
            onReorderItem: (oldIndex, newIndex) {
              final newOrder = List<AppTab>.of(order);
              final moved = newOrder.removeAt(oldIndex);
              newOrder.insert(newIndex, moved);
              state.setTabOrder(newOrder);
            },
            itemBuilder: (context, index) {
              final tab = order[index];
              final meta = kTabMeta[tab]!;
              final hidden = state.hiddenTabs.contains(tab);
              // Dernier onglet encore visible : son interrupteur reste
              // désactivé pour qu'on ne puisse jamais vider la barre du bas.
              final isOnlyVisible = !hidden && state.hiddenTabs.length >= order.length - 1;
              return Container(
                key: ValueKey(tab),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: Icon(meta.icon, color: hidden ? AppColors.ink.withValues(alpha: 0.3) : AppColors.accent),
                  title: Text(
                    meta.label,
                    style: AppTextStyles.sans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hidden ? AppColors.ink.withValues(alpha: 0.4) : AppColors.ink,
                    ),
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Switch(
                      value: !hidden,
                      onChanged: isOnlyVisible ? null : (v) => state.setTabHidden(tab, !v),
                    ),
                    const SizedBox(width: 4),
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.drag_handle, color: AppColors.ink.withValues(alpha: 0.35)),
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
