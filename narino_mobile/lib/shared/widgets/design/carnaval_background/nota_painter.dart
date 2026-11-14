import 'package:flutter/material.dart';
import 'carnaval_pintura.dart';

/// viewBox 0 0 24 24: corchea doble.
class NotaPainter extends CustomPainter {
  NotaPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = trazoCarnaval(color, 2 * k);
    final path = Path()
      ..moveTo(9 * k, 18 * k)
      ..lineTo(9 * k, 5 * k)
      ..lineTo(21 * k, 3 * k)
      ..lineTo(21 * k, 16 * k);
    canvas.drawPath(path, p);
    canvas.drawCircle(Offset(6 * k, 18 * k), 3 * k, p);
    canvas.drawCircle(Offset(18 * k, 16 * k), 3 * k, p);
  }

  @override
  bool shouldRepaint(NotaPainter old) => old.color != color;
}
