import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'glossary_icon.dart';

/// Champ numérique labellisé — équivalent de `Field` du prototype.
class NumberField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? suffix;
  final String? hint;
  /// Définition courte affichée via une icône "?" à côté du libellé —
  /// pour les champs au vocabulaire technique, sans quitter le formulaire.
  final String? glossaryDefinition;

  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.hint,
    this.glossaryDefinition,
  });

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();

  String _format(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    // `setState` à chaque changement de focus (pas seulement à la perte du
    // focus) — nécessaire pour faire réagir la bordure du champ (couleur
    // accent quand actif), en plus du reformatage existant à la perte du
    // focus.
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _controller.text = _format(widget.value);
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
            if (widget.glossaryDefinition != null)
              GlossaryIcon(term: widget.label, definition: widget.glossaryDefinition!),
            if (widget.hint != null) ...[
              const SizedBox(width: 6),
              Text(widget.hint!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySecondary().copyWith(fontSize: 11)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Bordure accent + ombre légère quand actif : seul repère de focus
        // avant (aucun), maintenant cohérent avec le reste de la refonte
        // (couleur du mode = accent en novice, violet en avancé).
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: _focusNode.hasFocus ? AppColors.accent : AppColors.border, width: _focusNode.hasFocus ? 1.5 : 1),
            boxShadow: _focusNode.hasFocus ? AppShadows.sm : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  style: AppTextStyles.mono(fontSize: 16, color: AppColors.ink),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    border: InputBorder.none,
                  ),
                  onChanged: (text) {
                    final parsed = double.tryParse(text.replaceAll(',', '.'));
                    widget.onChanged(parsed ?? 0);
                  },
                ),
              ),
              if (widget.suffix != null)
                Container(
                  // Padding réduit à 8 (au lieu de 12) : sur les mises en page
                  // à 3 champs par ligne (ex. comparatif d'offres de prêt),
                  // un suffixe de plusieurs lettres ("ans") pouvait laisser
                  // trop peu de place au nombre et rogner son dernier
                  // chiffre.
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: AppColors.paperSecondary, borderRadius: BorderRadius.circular(AppRadius.sm - 4)),
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(widget.suffix!, style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
