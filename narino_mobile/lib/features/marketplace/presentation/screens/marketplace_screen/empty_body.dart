import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class EmptyBody extends StatelessWidget {
  const EmptyBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Icon(Icons.storefront_outlined, color: textMuted, size: 64),
        ),
        const SizedBox(height: 14),
        Text(
          'No hay obras disponibles',
          style: AppTypography.bodyMedium(color: textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
