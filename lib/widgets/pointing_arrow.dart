import 'package:flutter/material.dart';

/// Petite flèche animée d'un aller-retour borné (quelques cycles puis elle
/// se fige) — utilisée dans le tuto pour désigner ce dont parle un slide.
/// Couleur vive volontairement à part du reste de la palette de l'app
/// (terre cuite/moutarde), pour "sauter aux yeux" comme demandé.
///
/// Bornée à un nombre fini d'allers-retours plutôt qu'un `repeat()`
/// indéfini : un `AnimationController` qui ne s'arrête jamais bloque
/// `WidgetTester.pumpAndSettle()` (déjà rencontré et corrigé sur
/// `PulsingHighlight`/`ArrivalBounce` ailleurs dans l'app).
class PointingArrow extends StatefulWidget {
  final Axis direction;
  const PointingArrow({super.key, this.direction = Axis.horizontal});

  @override
  State<PointingArrow> createState() => _PointingArrowState();
}

class _PointingArrowState extends State<PointingArrow> with SingleTickerProviderStateMixin {
  static const _cycles = 4;

  // Créé explicitement ici, jamais via un initialiseur de champ paresseux
  // (voir l'historique de `PulsingHighlight`/`ArrivalBounce`).
  late final AnimationController _controller;
  late final Animation<double> _offset;
  int _cyclesLeft = _cycles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _offset = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.addStatusListener(_onStatus);
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _cyclesLeft > 1) {
      _cyclesLeft--;
      _controller.reverse();
    } else if (status == AnimationStatus.dismissed && _cyclesLeft > 1) {
      _cyclesLeft--;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) {
        final dx = widget.direction == Axis.horizontal ? _offset.value * 6 : 0.0;
        final dy = widget.direction == Axis.vertical ? _offset.value * 6 : 0.0;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      // Rouge corail vif, distinct de l'accent (vert/violet) et des bandes
      // terre cuite/moutarde — un repère qui "pète" sans se confondre avec
      // le reste de la palette.
      child: Icon(
        widget.direction == Axis.horizontal ? Icons.arrow_forward_rounded : Icons.arrow_downward_rounded,
        color: const Color(0xFFFF5A5F),
        size: 22,
      ),
    );
  }
}
