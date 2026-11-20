import 'package:flutter/material.dart';
import 'carnaval_pintura.dart';

/// viewBox 0 0 100 100: círculo r20 + 8 rayos.
class SolPainter extends CustomPainter {
  SolPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    final p = trazoCarnaval(color, 2 * k);
    canvas.drawCircle(Offset(50 * k, 50 * k), 20 * k, p);
    const rays = [
      [50, 10, 50, 25],
      [50, 90, 50, 75],
      [10, 50, 25, 50],
      [90, 50, 75, 50],
      [22, 22, 32, 32],
      [78, 78, 68, 68],
      [22, 78, 32, 68],
      [78, 22, 68, 32],
    ];
    for (final r in rays) {
      canvas.drawLine(
          Offset(r[0] * k, r[1] * k), Offset(r[2] * k, r[3] * k), p);
    }
  }

  @override
  bool shouldRepaint(SolPainter old) => old.color != color;
}
