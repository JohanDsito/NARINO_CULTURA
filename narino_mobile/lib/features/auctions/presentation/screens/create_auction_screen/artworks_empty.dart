import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class ArtworksEmpty extends StatelessWidget {
  const ArtworksEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No tienes obras disponibles para subastar.',
              style: AppTypography.bodySmall(color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
