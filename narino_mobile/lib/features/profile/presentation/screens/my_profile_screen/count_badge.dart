import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

// ─── Badge de conteo ──────────────────────────────────────────────────────────

class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$count',
        style: AppTypography.caption(color: cs.primary),
      ),
    );
  }
}
