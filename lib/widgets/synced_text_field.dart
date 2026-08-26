import 'package:flutter/material.dart';

/// Champ texte dont le contrôleur reste stable entre les rebuilds (évite de
/// perdre le curseur/focus à chaque frappe quand la valeur vient d'un
/// [ChangeNotifier] externe) — utilisé pour le nom du bien et des offres.
class SyncedTextField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final TextStyle? style;
  final InputDecoration decoration;

  const SyncedTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.style,
    this.decoration = const InputDecoration(isDense: true, border: InputBorder.none),
  });

  @override
  State<SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<SyncedTextField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);
  final _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant SyncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
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
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      style: widget.style,
      decoration: widget.decoration,
    );
  }
}
