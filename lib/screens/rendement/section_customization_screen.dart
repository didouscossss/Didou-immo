import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_tab.dart';
import '../../models/tab_sections.dart';
import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';
import 'app_tab_meta.dart';

/// "Personnaliser [onglet]" — réordonne (glisser via la poignée) et
/// masque/affiche les blocs à l'intérieur d'un onglet donné. Même principe
/// que `TabCustomizationScreen`, un cran plus fin (voir `kTabSections`,
/// `RendementState.sectionOrder`/`hiddenSections`).
class SectionCustomizationScreen extends StatelessWidget {
  final AppTab tab;
  const SectionCustomizationScreen({super.key, required this.tab});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    final meta = kTabSections[tab]!;
    final order = state.sectionOrder(tab);
    final hiddenSections = state.hiddenSections(tab);

    return Scaffold(
      appBar: AppBar(
        title: Text('Personnaliser "${kTabMeta[tab]!.label}"'),
        actions: [
          TextButton(
            onPressed: () => state.resetSectionLayout(tab),
            child: Text('Réinitialiser', style: AppTextStyles.sans(fontSize: 13, color: AppColors.accent)),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            meta.lockedId == null
                ? 'Fais glisser la poignée pour réordonner les blocs de cet onglet, ou masque ceux dont tu ne te sers pas.'
                : 'Fais glisser la poignée pour réordonner les blocs de cet onglet, ou masque ceux dont tu ne te sers pas. '
                    '"${meta.labels[meta.lockedId]}" ne peut pas être masqué, mais reste déplaçable.',
            style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.6)),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: order.length,
            onReorderItem: (oldIndex, newIndex) {
              final newOrder = List<String>.of(order);
              final moved = newOrder.removeAt(oldIndex);
              newOrder.insert(newIndex, moved);
              state.setSectionOrder(tab, newOrder);
            },
            itemBuilder: (context, index) {
              final id = order[index];
              final label = meta.labels[id] ?? id;
              final hidden = hiddenSections.contains(id);
              final locked = id == meta.lockedId;
              final isOnlyVisible = !hidden && !locked && hiddenSections.length >= order.length - 1;
              return Container(
                key: ValueKey(id),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  title: Text(
                    label,
                    style: AppTextStyles.sans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hidden ? AppColors.ink.withValues(alpha: 0.4) : AppColors.ink,
                    ),
                  ),
                  subtitle: locked ? Text('Toujours visible', style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.45))) : null,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Switch(
                      value: !hidden,
                      onChanged: locked || isOnlyVisible ? null : (v) => state.setSectionHidden(tab, id, !v),
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
