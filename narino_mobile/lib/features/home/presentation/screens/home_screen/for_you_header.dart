import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class ForYouHeader extends StatelessWidget {
  const ForYouHeader({required this.loading, super.key});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Para ti',
                  style: AppTypography.displaySemiBold(color: textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  'Recomendaciones basadas en tu actividad',
                  style: AppTypography.bodySmall(color: textSecondary),
                ),
              ],
            ),
          ),
          if (loading)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: cs.primary),
              ),
            ),
        ],
      ),
    );
  }
}
