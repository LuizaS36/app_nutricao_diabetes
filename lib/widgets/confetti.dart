import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// Chuva de confete quando a meta de água é atingida. Some sozinha ao terminar.
class ConfettiLayer extends StatefulWidget {
  const ConfettiLayer({super.key, this.onDone});
  final VoidCallback? onDone;
  @override
  State<ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<ConfettiLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone?.call();
    })
    ..forward();
  static const _colors = [AppColors.teal, AppColors.lime, Color(0xFFD97B68), Color(0xFF8A78B8)];

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Stack(children: [
            for (var i = 0; i < 24; i++) _piece(i, box.maxHeight),
          ]),
        ),
      );

  Widget _piece(int i, double h) {
    final delay = (i % 8) * .06;
    final t = ((_c.value - delay) / (1 - delay)).clamp(0.0, 1.0);
    return Positioned(
      left: ((i * 0.137) % 0.92 + 0.03) * MediaQuery.of(context).size.width,
      top: -20 + t * (h + 40),
      child: Opacity(
        opacity: 1 - .85 * t,
        child: Transform.rotate(
          angle: t * 4 * math.pi,
          child: Container(width: 8, height: 14, decoration: BoxDecoration(color: _colors[i % 4], borderRadius: BorderRadius.circular(2))),
        ),
      ),
    );
  }
}
