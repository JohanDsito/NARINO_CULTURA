import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Paso numerado ────────────────────────────────────────────────────────────

class VerifyStep extends StatelessWidget {
  const VerifyStep({
    super.key,
    required this.number,
    required this.text,
    required this.textColor,
    required this.mutedColor,
  });

  final String number;
  final String text;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.oroAndino.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              number,
              style: AppTypography.labelSemiBold(color: AppColors.oroAndino)
                  .copyWith(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall(color: textColor),
          ),
        ),
      ],
    );
  }
}
