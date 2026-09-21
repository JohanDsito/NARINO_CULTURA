import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    return Container(
      height: height,
      color: bgSubtle,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
