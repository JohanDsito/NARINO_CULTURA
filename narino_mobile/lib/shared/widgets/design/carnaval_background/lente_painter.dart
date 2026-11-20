import 'package:flutter/material.dart';
import 'carnaval_pintura.dart';

/// viewBox 0 0 100 100: lente de cámara.
class LentePainter extends CustomPainter {
  LentePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    final p = trazoCarnaval(color, 2 * k);
    final c = Offset(50 * k, 50 * k);
    canvas.drawCircle(c, 40 * k, p);
    canvas.drawCircle(c, 25 * k, p);
    const lines = [
      [50, 25, 65, 10],
      [50, 75, 35, 90],
      [25, 50, 10, 35],
      [75, 50, 90, 65],
    ];
    for (final l in lines) {
      canvas.drawLine(
          Offset(l[0] * k, l[1] * k), Offset(l[2] * k, l[3] * k), p);
    }
  }

  @override
  bool shouldRepaint(LentePainter old) => old.color != color;
}
