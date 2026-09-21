import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class PlaceholderBox extends StatelessWidget {
  const PlaceholderBox({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      width: 56,
      height: 56,
      color: bgSubtle,
      child: Icon(Icons.image_outlined, color: textMuted, size: 24),
    );
  }
}
