import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Stat dentro de la tarjeta ────────────────────────────────────────────────

class Stat extends StatelessWidget {
  const Stat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.displaySemiBold(color: textPrimary)
                .copyWith(fontSize: 20),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption(color: textMuted)),
        ],
      ),
    );
  }
}
