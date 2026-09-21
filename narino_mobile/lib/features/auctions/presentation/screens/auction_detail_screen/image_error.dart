import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class ImageError extends StatelessWidget {
  const ImageError({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Icon(Icons.image_outlined, size: 52, color: textMuted),
      ),
    );
  }
}
