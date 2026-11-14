import 'package:flutter/material.dart';

// ─── Formas (mismos trazos que los SVG del diseño) ───────────────────────────

Paint trazoCarnaval(Color c, double width) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;
