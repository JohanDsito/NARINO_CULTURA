import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Hero del registro ────────────────────────────────────────────────────────

class RegisterHero extends StatelessWidget {
  const RegisterHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.obsidiana,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.oroAndino,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.landscape_outlined,
                  size: 26, color: AppColors.obsidiana),
            ),
            const SizedBox(width: 12),
            Text(
              'Nariño Cultura',
              style: AppTypography.displayBold(color: AppColors.oroClaro)
                  .copyWith(fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}
