import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class StatDivider extends StatelessWidget {
  const StatDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 32,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
