import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Hero del login.
class LoginHero extends StatelessWidget {
  const LoginHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.obsidiana,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.oroAndino,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.landscape_outlined,
                size: 40,
                color: AppColors.obsidiana,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Nariño Cultura',
              style: AppTypography.displayBold(color: AppColors.oroClaro),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Arte que nace desde Nariño',
              style: AppTypography.quoteItalic(
                color: AppColors.oroClaro.withValues(alpha: 0.70),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
