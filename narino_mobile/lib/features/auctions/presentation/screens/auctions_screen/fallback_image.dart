import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class FallbackImage extends StatelessWidget {
  const FallbackImage({super.key, this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      width: 78,
      height: 78,
      color: bgSubtle,
      child: Center(
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.image_outlined, color: textMuted, size: 28),
      ),
    );
  }
}
