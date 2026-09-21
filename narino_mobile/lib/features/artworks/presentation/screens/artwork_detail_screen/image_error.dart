import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class ImageError extends StatelessWidget {
  const ImageError({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final iconColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      color: bgSubtle,
      child: Icon(Icons.image_outlined, size: 60, color: iconColor),
    );
  }
}
