import 'dart:async';
import 'package:flutter/material.dart';

/// Petit rebond (~700 ms) joué quand un bouton important apparaît sur
/// l'écran ou redevient pertinent, puis répété toutes les 3 secondes tant
/// que le bouton reste visible — pas un signal permanent qui reste allumé
/// (voir l'ancien halo `PulsingHighlight`, jugé trop "surveillance" par
/// l'utilisateur), mais un petit geste régulier façon "je suis là si tu as
/// besoin !".
///
/// [active] pilote le déclenchement : `true` dès le montage (ou passant de
/// `false` à `true` en cours de vie, ex. un champ qui devient valide) fait
/// jouer le rebond puis relance la répétition ; repasser à `false` arrête la
/// répétition et fige le bouton dans son état normal.
class ArrivalBounce extends StatefulWidget {
  final Widget child;
  final bool active;

  const ArrivalBounce({super.key, required this.child, this.active = true});

  @override
  State<ArrivalBounce> createState() => _ArrivalBounceState();
}

class _ArrivalBounceState extends State<ArrivalBounce> with SingleTickerProviderStateMixin {
  // Créé explicitement ici, jamais via un initialiseur de champ paresseux
  // (`late final ... = ...`) — voir l'historique de `PulsingHighlight` :
  // un tel champ ne s'évalue qu'au premier ACCÈS réel, ce qui peut retomber
  // sur `dispose()` si `active` valait déjà `false` en permanence, où
  // chercher un ancêtre (requis par `createTicker`) plante ("Looking up a
  // deactivated widget's ancestor is unsafe").
  late final AnimationController _controller;
  late final Animation<double> _bounce;
  Timer? _repeatTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _bounce = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    if (widget.active) {
      _controller.forward();
      _startRepeating();
    }
  }

  // Un `Timer.periodic` (et non un `AnimationController.repeat()`) : ce
  // dernier ne termine jamais et bloque `WidgetTester.pumpAndSettle()`
  // indéfiniment (cause du crash de CI de la PR #95). Le timer, lui, ne
  // fait que relancer un rebond borné (700 ms) toutes les 3 secondes, donc
  // `pumpAndSettle()` retrouve toujours un état stable entre deux tirs.
  void _startRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(covariant ArrivalBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
      _startRepeating();
    } else if (!widget.active && oldWidget.active) {
      _repeatTimer?.cancel();
      _repeatTimer = null;
    }
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _bounce,
      // Part légèrement petit puis dépasse un instant la taille normale
      // avant de s'y stabiliser (élasticité de la courbe) — l'effet de
      // "rebond" vient de ce dépassement, répété par le timer ci-dessus.
      builder: (context, child) => Transform.scale(scale: 0.82 + 0.18 * _bounce.value, child: child),
      child: widget.child,
    );
  }
}
