import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class ImageEmpty extends StatelessWidget {
  const ImageEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final iconColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      color: bgSubtle,
      child: Icon(Icons.palette_outlined, size: 60, color: iconColor),
    );
  }
}
