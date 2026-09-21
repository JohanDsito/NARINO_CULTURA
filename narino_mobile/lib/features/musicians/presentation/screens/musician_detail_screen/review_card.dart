import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/musician_model.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, required this.isDark});

  final MusicianReviewModel review;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgCard = theme.cardTheme.color ?? theme.colorScheme.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.indigoClaro.withValues(alpha: 0.2),
                backgroundImage: review.reviewerAvatar != null
                    ? CachedNetworkImageProvider(review.reviewerAvatar!)
                    : null,
                child: review.reviewerAvatar == null
                    ? Text(
                        review.reviewerName.isNotEmpty
                            ? review.reviewerName[0].toUpperCase()
                            : '?',
                        style: AppTypography.labelSemiBold(
                            color: AppColors.indigoClaro),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName,
                        style:
                            AppTypography.labelSemiBold(color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating
                              ? Icons.star
                              : Icons.star_outline,
                          size: 13,
                          color: i < review.rating
                              ? AppColors.oroAndino
                              : textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: AppTypography.caption(color: textMuted),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!,
                style: AppTypography.bodySmall(color: textMuted)),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  return '${dt.day}/${dt.month}/${dt.year}';
}
