import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class Dot extends StatelessWidget {
  const Dot({super.key, required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: textMuted,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
