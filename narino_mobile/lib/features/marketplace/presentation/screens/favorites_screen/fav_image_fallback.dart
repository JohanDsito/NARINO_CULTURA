import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

// ─── Imagen de respaldo del favorito ───────────────────────────────────────────

class FavImageFallback extends StatelessWidget {
  const FavImageFallback({super.key, this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      color: bgSubtle,
      child: Center(
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.image_outlined, color: textMuted),
      ),
    );
  }
}
