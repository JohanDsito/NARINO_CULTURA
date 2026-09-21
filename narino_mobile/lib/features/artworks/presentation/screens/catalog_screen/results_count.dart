import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Contador de resultados ───────────────────────────────────────────────────

class ResultsCount extends StatelessWidget {
  const ResultsCount({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$count obras encontradas',
          style: AppTypography.caption(color: textMuted),
        ),
      ),
    );
  }
}
