import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Row(
      children: [
        Icon(icon, size: 16, color: textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelSemiBold(color: textSecondary),
        ),
      ],
    );
  }
}
