import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class FeaturedPill extends StatelessWidget {
  const FeaturedPill({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark ? AppColors.bgSubtleDark : AppColors.oroPalido;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '⭐ Destacado',
        style: AppTypography.caption(color: AppColors.oroAndino),
      ),
    );
  }
}
