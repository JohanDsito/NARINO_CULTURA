import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class EmptyBody extends StatelessWidget {
  const EmptyBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 90),
        Center(child: Icon(Icons.gavel_outlined, size: 56, color: iconColor)),
        const SizedBox(height: 14),
        Text(
          'No hay subastas activas en este momento.',
          style: AppTypography.bodyMedium(color: textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
