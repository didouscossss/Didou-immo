import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bien_section.dart';
import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';

/// "Personnaliser les sections" de l'onglet "Bien" — même principe que
/// `TabCustomizationScreen`, mais pour les blocs à l'intérieur de cet
/// onglet plutôt que les onglets eux-mêmes. Voir `RendementState.
/// bienSectionOrder`/`bienHiddenSections`.
class BienSectionCustomizationScreen extends StatelessWidget {
  const BienSectionCustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    final order = state.bienSectionOrder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personnaliser "Bien"'),
        actions: [
          TextButton(
            onPressed: state.resetBienSectionLayout,
            child: Text('Réinitialiser', style: AppTextStyles.sans(fontSize: 13, color: AppColors.accent)),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            'Fais glisser la poignée pour réordonner les blocs de cet onglet, ou masque ceux dont tu ne te sers pas. '
            '"Enregistrer ce bien" ne peut pas être masqué, mais reste déplaçable.',
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
              state.setBienSectionOrder(newOrder);
            },
            itemBuilder: (context, index) {
              final id = order[index];
              final label = kBienSectionLabels[id] ?? id;
              final hidden = state.bienHiddenSections.contains(id);
              final locked = id == kBienSaveSectionId;
              final isOnlyVisible = !hidden && !locked && state.bienHiddenSections.length >= order.length - 1;
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
                      onChanged: locked || isOnlyVisible ? null : (v) => state.setBienSectionHidden(id, !v),
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
