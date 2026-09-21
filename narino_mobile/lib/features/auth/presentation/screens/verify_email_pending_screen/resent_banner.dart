import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Banner de reenvío exitoso ────────────────────────────────────────────────

class ResentBanner extends StatelessWidget {
  const ResentBanner({super.key, required this.textPrimary});

  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 18, color: AppColors.success),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Correo reenviado. Revisa tu bandeja de entrada.',
              style: AppTypography.bodySmall(color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
