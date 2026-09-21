import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class EmptySales extends StatelessWidget {
  const EmptySales({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 48),
          Icon(Icons.storefront_outlined, size: 56, color: iconColor),
          const SizedBox(height: 14),
          Text(
            'Aún no tienes ventas.',
            style: AppTypography.bodyMedium(color: textMuted),
          ),
        ],
      ),
    );
  }
}
