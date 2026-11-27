import 'package:flutter/material.dart';
import '../theme.dart';
import 'dart:math' as math;
import '../models.dart';

/// Curva definida como no SVG do React: ponto inicial + segmentos cúbicos
/// (x1,y1,x2,y2,x,y) dentro de uma "viewBox" [vw] x [vh].
class CurvePainter extends CustomPainter {
  CurvePainter({
    required this.start,
    required this.segments,
    required this.vw,
    required this.vh,
    this.color = AppColors.teal,
    this.strokeWidth = 2.5,
    this.dot,
    this.goalZone,
    this.gridStep,
  });
  final Offset start;
  final List<List<double>> segments;
  final double vw, vh, strokeWidth;
  final Color color;
  final Offset? dot;
  final Rect? goalZone; // em unidades da viewBox
  final double? gridStep;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / vw, sy = size.height / vh;
    if (gridStep != null) {
      final grid = Paint()..color = const Color(0xFFEDF1E3)..strokeWidth = 1;
      for (var y = gridStep!; y < vh; y += gridStep!) {
        canvas.drawLine(Offset(0, y * sy), Offset(size.width, y * sy), grid);
      }
    }
    if (goalZone != null) {
      final g = goalZone!;
      canvas.drawRect(Rect.fromLTWH(g.left * sx, g.top * sy, g.width * sx, g.height * sy), Paint()..color = AppColors.mint.withValues(alpha: .5));
    }
    final p = Path()..moveTo(start.dx * sx, start.dy * sy);
    for (final s in segments) {
      p.cubicTo(s[0] * sx, s[1] * sy, s[2] * sx, s[3] * sy, s[4] * sx, s[5] * sy);
    }
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
    if (dot != null) {
      canvas.drawCircle(Offset(dot!.dx * sx, dot!.dy * sy), 2.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CurvePainter old) => old.color != color || old.dot != dot;
}

/// Gráfico "Evolução da glicemia" (7 dias) com faixa da meta.
class GlucoseChart extends StatelessWidget {
  const GlucoseChart({super.key, this.height = 180});
  final double height;

  static const _months = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final labels = [
      for (var i = 6; i >= 1; i--)
        '${now.subtract(Duration(days: i)).day} ${_months[now.subtract(Duration(days: i)).month - 1]}',
      'Hoje',
    ];
    return Column(children: [
      SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: CurvePainter(
            start: const Offset(0, 110),
            segments: const [
              [70, 100, 85, 55, 145, 77],
              [205, 99, 230, 125, 290, 90],
              [350, 55, 360, 34, 430, 66],
              [500, 98, 520, 130, 580, 87],
              [640, 44, 650, 58, 700, 70],
            ],
            vw: 700,
            vh: 180,
            goalZone: const Rect.fromLTWH(0, 55, 700, 70),
            gridStep: 45,
          ),
        ),
      ),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [for (final l in labels) Text(l, style: const TextStyle(fontSize: 9, color: AppColors.muted))],
      ),
    ]);
  }
}

/// Mini gráfico do card de glicemia da visão geral.
class MiniGlucoseChart extends StatelessWidget {
  const MiniGlucoseChart({super.key});
  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
          height: 52,
          width: double.infinity,
          child: CustomPaint(
            painter: CurvePainter(
              start: const Offset(0, 42),
              segments: const [
                [50, 44, 60, 20, 110, 28],
                [160, 36, 175, 48, 215, 30],
                [255, 12, 270, 10, 310, 31],
                [350, 52, 360, 44, 400, 18],
              ],
              vw: 400,
              vh: 60,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Hoje'])
              Text(l, style: const TextStyle(fontSize: 9, color: AppColors.muted)),
          ],
        ),
      ]);
}

/// Curvinha ao lado de cada registro de glicemia.
class GlucoseSparkline extends StatelessWidget {
  const GlucoseSparkline({super.key, required this.value, required this.index});
  final int value;
  final int index;

  static const List<(Offset, List<List<double>>)> _variants = [
    (Offset(2, 18), [[12.0, 16, 16, 6, 27, 10], [38.0, 14, 42, 20, 54, 8], [66.0, -4, 67, 5, 78, 12]]),
    (Offset(2, 12), [[14.0, 4, 20, 18, 31, 13], [42.0, 8, 48, 5, 58, 11], [68.0, 17, 69, 19, 78, 7]]),
    (Offset(2, 16), [[11.0, 8, 21, 9, 30, 15], [39.0, 21, 46, 19, 56, 9], [66.0, -1, 69, 4, 78, 10]]),
  ];

  @override
  Widget build(BuildContext context) {
    final v = _variants[index % _variants.length];
    final color = value > 140 ? AppColors.warn : AppColors.teal;
    return SizedBox(
      width: 56,
      height: 22,
      child: CustomPaint(
        painter: CurvePainter(
          start: v.$1,
          segments: v.$2,
          vw: 80,
          vh: 24,
          color: color,
          strokeWidth: 2,
          dot: Offset(78, index % 2 == 0 ? 12 : 7),
        ),
      ),
    );
  }
}

/// Gráfico das últimas medições, com eixo Y (mg/dL), eixo X (horário) e faixa da meta (70–140).
class GlucoseHistoryChart extends StatelessWidget {
  const GlucoseHistoryChart({super.key, required this.logs, this.height = 180, this.maxPoints = 7});
  final List<GlucoseLog> logs; // mais recente primeiro
  final double height;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    final data = logs.take(maxPoints).toList().reversed.toList(); // do mais antigo ao mais recente
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Sem medições para mostrar.', style: TextStyle(color: AppColors.muted))),
      );
    }
    return SizedBox(height: height, width: double.infinity, child: CustomPaint(painter: _AxesChartPainter(data)));
  }
}

class _AxesChartPainter extends CustomPainter {
  _AxesChartPainter(this.data);
  final List<GlucoseLog> data;

  static const double left = 34, right = 8, top = 16, bottom = 22;

  void _text(Canvas c, String t, Offset o, {bool centerX = false, bool alignRight = false}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: const TextStyle(fontSize: 9, color: AppColors.muted)),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = o.dx;
    if (centerX) dx -= tp.width / 2;
    if (alignRight) dx -= tp.width;
    tp.paint(c, Offset(dx, o.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    final maxV = data.map((e) => e.value).reduce(math.max);
    const yMin = 40.0;
    final yMax = math.max(200, (maxV / 50).ceil() * 50).toDouble();
    double yOf(num v) => plot.bottom - ((v - yMin) / (yMax - yMin)).clamp(0.0, 1.0) * plot.height;

    // faixa da meta
    canvas.drawRect(
      Rect.fromLTRB(plot.left, yOf(140), plot.right, yOf(70)),
      Paint()..color = AppColors.mint.withValues(alpha: .5),
    );

    // grade + rótulos do eixo Y
    final grid = Paint()..color = const Color(0xFFEDF1E3)..strokeWidth = 1;
    for (var v = 50.0; v <= yMax; v += 50) {
      canvas.drawLine(Offset(plot.left, yOf(v)), Offset(plot.right, yOf(v)), grid);
      _text(canvas, '${v.toInt()}', Offset(left - 6, yOf(v)), alignRight: true);
    }
    _text(canvas, 'mg/dL', const Offset(0, 6));

    // eixos
    final axis = Paint()..color = AppColors.muted.withValues(alpha: .5)..strokeWidth = 1;
    canvas.drawLine(plot.bottomLeft, plot.topLeft, axis);
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axis);

    // pontos, linha e rótulos do eixo X
    final n = data.length;
    Offset pt(int i) {
      final x = n == 1 ? plot.center.dx : plot.left + 14 + i * (plot.width - 28) / (n - 1);
      return Offset(x, yOf(data[i].value));
    }

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < n; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < n; i++) {
      final p = pt(i);
      canvas.drawCircle(p, 3.5, Paint()..color = data[i].value > 140 ? AppColors.warn : AppColors.teal);
      _text(canvas, data[i].time, Offset(p.dx, plot.bottom + 12), centerX: true);
    }
  }

  @override
  bool shouldRepaint(covariant _AxesChartPainter old) => true;
}
