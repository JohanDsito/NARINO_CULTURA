import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class SectionDivider extends StatelessWidget {
  const SectionDivider({
    super.key,
    required this.label,
    required this.textMuted,
  });

  final String label;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(label,
            style: AppTypography.labelSemiBold(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            )),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
        ),
      ],
    );
  }
}
