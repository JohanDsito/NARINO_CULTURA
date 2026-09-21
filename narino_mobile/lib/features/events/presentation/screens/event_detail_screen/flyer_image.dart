import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

// ─── Imagen del flyer ─────────────────────────────────────────────────────────

class FlyerImage extends StatelessWidget {
  const FlyerImage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgSubtle =
            isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
        return Container(
          color: bgSubtle,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, __, ___) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgSubtle =
            isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
        final textMuted =
            isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
        return Container(
          color: bgSubtle,
          child: Icon(Icons.image_outlined, color: textMuted, size: 60),
        );
      },
    );
  }
}
