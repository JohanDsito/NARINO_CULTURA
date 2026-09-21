import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../providers/auctions_provider.dart';

class EmptyHistory extends StatelessWidget {
  const EmptyHistory({super.key, required this.params});

  final AuctionHistoryParams params;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final isPujas = params.mode == 'participante';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gavel_outlined, size: 52, color: iconColor),
            const SizedBox(height: 14),
            Text(
              isPujas
                  ? 'Aún no has participado en subastas.'
                  : 'Aún no has creado subastas.',
              style: AppTypography.bodyMedium(color: textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
