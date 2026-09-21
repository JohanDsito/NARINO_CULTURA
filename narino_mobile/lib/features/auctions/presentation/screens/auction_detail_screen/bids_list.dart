import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/auction_bid_model.dart';

class BidsList extends StatelessWidget {
  const BidsList({super.key, required this.bids});

  final List<AuctionBidModel> bids;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    if (bids.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.gavel_outlined, size: 18, color: textMuted),
            const SizedBox(width: 8),
            Text(
              'Aún no hay pujas. ¡Sé el primero!',
              style: AppTypography.bodySmall(color: textMuted),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: bids.asMap().entries.map((entry) {
          final i = entry.key;
          final bid = entry.value;
          final isLast = i == bids.length - 1;
          final isTop = i == 0;

          return Container(
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: border)),
            ),
            child: ListTile(
              dense: true,
              leading: isTop
                  ? const Icon(Icons.emoji_events_outlined,
                      size: 18, color: AppColors.oroAndino)
                  : Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        '${i + 1}',
                        style: AppTypography.caption(color: textMuted),
                      ),
                    ),
              title: Text(
                bid.bidderName,
                style: AppTypography.bodySmall(color: textPrimary),
              ),
              trailing: Text(
                '\$${bid.amount.toStringAsFixed(0)}',
                style: AppTypography.labelSemiBold(
                    color: isTop ? AppColors.oroAndino : cs.primary),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
