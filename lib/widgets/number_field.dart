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
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _controller.text = _format(widget.value));
      }
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
                style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
              ),
            ),
            if (widget.glossaryDefinition != null)
              GlossaryIcon(term: widget.label, definition: widget.glossaryDefinition!),
            if (widget.hint != null) ...[
              const SizedBox(width: 6),
              Text(widget.hint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.6))),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  style: AppTextStyles.mono(fontSize: 15, color: const Color(0xFF16211C)),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: AppColors.border))),
                  height: 44,
                  alignment: Alignment.center,
                  child: Text(widget.suffix!, style: AppTextStyles.sans(fontSize: 13, color: const Color(0xFF16211C).withValues(alpha: 0.55))),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
