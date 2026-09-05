import 'package:flutter/material.dart';

/// Petit rebond d'arrivée (~700 ms, un seul coup) joué quand un bouton
/// important apparaît sur l'écran ou redevient pertinent — pas un signal
/// permanent qui reste allumé, juste un geste ponctuel façon "je suis là si
/// tu as besoin !". Remplace l'ancien halo/grossissement continu
/// (`PulsingHighlight`), jugé trop "surveillance" à l'usage par
/// l'utilisateur : ici, une fois le rebond joué, le bouton redevient
/// parfaitement normal, sans rien laisser en place (pas de halo résiduel).
///
/// [active] pilote le déclenchement : `true` dès le montage (ou passant de
/// `false` à `true` en cours de vie, ex. un champ qui devient valide) fait
/// jouer le rebond une fois ; repasser à `false` puis `true` le rejoue.
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _bounce = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    if (widget.active) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ArrivalBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
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
      animation: _bounce,
      // Part légèrement petit puis dépasse un instant la taille normale
      // avant de s'y stabiliser (élasticité de la courbe) — l'effet de
      // "rebond" vient de ce dépassement, pas d'une boucle qui continue.
      builder: (context, child) => Transform.scale(scale: 0.82 + 0.18 * _bounce.value, child: child),
      child: widget.child,
    );
  }
}
