import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class OwnerAuctionNotice extends StatelessWidget {
  const OwnerAuctionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final bgCard = isDark ? AppColors.bgCardDark : AppColors.bgCardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Eres el propietario de esta subasta',
              style: AppTypography.caption(color: textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
