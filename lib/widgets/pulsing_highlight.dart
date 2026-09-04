import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Halo lumineux animé (respiration douce, ~1,5 s par battement) à poser
/// autour d'un bouton pour attirer l'œil dessus — utilisé sur les boutons
/// d'action vraiment importants (enregistrer un changement non sauvegardé,
/// passer en illimité...), pas systématiquement sur tous les boutons de
/// l'app : un signal qui pulse partout n'attire plus l'attention nulle
/// part.
///
/// Bat un nombre FINI de fois ([cycles], 3 par défaut) puis se stabilise
/// sur un halo fixe (pas de retour à zéro) plutôt que de pulser sans fin :
/// au-delà de quelques secondes, une animation infinie distrait plus
/// qu'elle n'attire l'attention — et surtout, une [AnimationController] en
/// `repeat()` sans fin ne s'arrête jamais de son plein gré, ce qui bloque
/// indéfiniment `WidgetTester.pumpAndSettle()` dans les tests (vécu en CI :
/// bloquait 5 tests qui n'ont pourtant rien à voir avec ce widget).
///
/// Couleur liée à [AppColors.accent] : s'adapte donc automatiquement au
/// thème (clair/sombre, novice/avancé) sans configuration.
///
/// [active] pilote l'animation à la demande (ex. seulement tant qu'il y a
/// des modifications non enregistrées) — à `false`, le halo disparaît et
/// l'enfant s'affiche tel quel, sans le coût de l'animation. Redevenir
/// actif après être retombé à `false` relance la série de battements
/// depuis le début.
class PulsingHighlight extends StatefulWidget {
  final Widget child;
  final bool active;
  final BorderRadius borderRadius;
  final int cycles;

  const PulsingHighlight({
    super.key,
    required this.child,
    this.active = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.cycles = 3,
  });

  @override
  State<PulsingHighlight> createState() => _PulsingHighlightState();
}

class _PulsingHighlightState extends State<PulsingHighlight> with SingleTickerProviderStateMixin {
  // Créé explicitement dans initState() ci-dessous, jamais via un
  // initialiseur de champ paresseux (`late final ... = ...`) : ce dernier
  // ne s'évaluerait qu'au premier ACCÈS réel au champ — si [active] est
  // `false` dès la création (ex. bien déjà enregistré, sans modification),
  // `build()` ne le touche jamais, et le premier accès deviendrait alors
  // celui de `dispose()` ci-dessous, où chercher un ancêtre (nécessaire à
  // `createTicker`) plante ("Looking up a deactivated widget's ancestor is
  // unsafe") : l'élément est déjà en cours de démontage à ce moment-là.
  late final AnimationController _controller;
  int _remainingCycles = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..addStatusListener(_onStatusChanged);
    if (widget.active) _startPulsing();
  }

  void _startPulsing() {
    _remainingCycles = widget.cycles;
    _controller.forward(from: 0);
  }

  /// Alterne forward/reverse jusqu'à épuisement de [_remainingCycles], puis
  /// laisse le contrôleur se stabiliser à `1.0` (halo fixe) sans le
  /// relancer — c'est ce qui garantit une animation bornée dans le temps.
  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _remainingCycles--;
      if (_remainingCycles > 0) _controller.reverse();
    } else if (status == AnimationStatus.dismissed && _remainingCycles > 0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant PulsingHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startPulsing();
    } else if (!widget.active && oldWidget.active) {
      _remainingCycles = 0;
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
              color: AppColors.accent.withValues(alpha: 0.12 + 0.28 * _controller.value),
              blurRadius: 6 + 12 * _controller.value,
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
