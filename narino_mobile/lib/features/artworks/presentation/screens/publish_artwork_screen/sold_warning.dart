import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'field_padding.dart';

class SoldWarning extends StatelessWidget {
  const SoldWarning({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgColor = textMuted.withValues(alpha: 0.08);

    return Container(
      padding: kFieldPadding,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Esta obra ya fue vendida. Solo puedes archivarla.',
              style: AppTypography.bodySmall(color: textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
