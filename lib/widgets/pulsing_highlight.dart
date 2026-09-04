import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Halo lumineux animé (respiration douce, ~1,5 s par cycle) à poser autour
/// d'un bouton pour attirer l'œil dessus — utilisé sur les boutons d'action
/// vraiment importants (valider une action attendue, enregistrer un
/// changement non sauvegardé, passer en illimité...), pas systématiquement
/// sur tous les boutons de l'app : un signal qui pulse partout n'attire
/// plus l'attention nulle part.
///
/// Couleur liée à [AppColors.accent] : s'adapte donc automatiquement au
/// thème (clair/sombre, novice/avancé) sans configuration.
///
/// [active] pilote l'animation à la demande (ex. seulement tant qu'il y a
/// des modifications non enregistrées) — à `false`, le halo disparaît et
/// l'enfant s'affiche tel quel, sans le coût de l'animation.
class PulsingHighlight extends StatefulWidget {
  final Widget child;
  final bool active;
  final BorderRadius borderRadius;

  const PulsingHighlight({
    super.key,
    required this.child,
    this.active = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<PulsingHighlight> createState() => _PulsingHighlightState();
}

class _PulsingHighlightState extends State<PulsingHighlight> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PulsingHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.15 + 0.25 * _controller.value),
              blurRadius: 8 + 10 * _controller.value,
              spreadRadius: 1 + 2 * _controller.value,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}
