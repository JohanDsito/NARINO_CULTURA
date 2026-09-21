import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../providers/musician_provider.dart';
import 'review_card.dart';

class ReviewsTab extends ConsumerWidget {
  const ReviewsTab({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(musicianReviewsProvider(slug));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return reviewsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.indigoClaro),
      ),
      error: (e, _) => Center(
        child: Text(e.toString(),
            style: AppTypography.bodyMedium(color: AppColors.error)),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 48, color: textMuted),
                const SizedBox(height: 12),
                Text('Aún no hay reseñas',
                    style: AppTypography.bodyMedium(color: textMuted)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) =>
              ReviewCard(review: reviews[i], isDark: isDark),
        );
      },
    );
  }
}
