import 'package:flutter/material.dart';

// ─── Accesos rápidos ──────────────────────────────────────────────────────────

class QuickItem {
  const QuickItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String route;
  final Color color;
}
