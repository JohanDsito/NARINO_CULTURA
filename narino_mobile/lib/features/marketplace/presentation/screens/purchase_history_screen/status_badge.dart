import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

// ─── Badge de estado ──────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.colors,
  });

  final String label;
  final ({Color bg, Color fg}) colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTypography.caption(color: colors.fg),
      ),
    );
  }
}
