import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/musician_model.dart';
import 'stat.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({
    super.key,
    required this.musician,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
  });

  final MusicianModel musician;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgCard = theme.cardTheme.color ?? theme.colorScheme.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      color: bgCard,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (musician.bio != null && musician.bio!.isNotEmpty) ...[
            Text(
              musician.bio!,
              style: AppTypography.bodySmall(color: textMuted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
          ],
          if (musician.genres.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: musician.genres.map((g) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        AppColors.indigoClaro.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: AppColors.indigoClaro
                            .withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    g,
                    style: AppTypography.caption(
                        color: AppColors.indigoClaro),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Stat(
                icon: Icons.people_outline,
                value: '${musician.followersCount}',
                label: 'Seguidores',
                color: textMuted,
              ),
              const SizedBox(width: 24),
              Stat(
                icon: Icons.star_outline,
                value: musician.averageRating.toStringAsFixed(1),
                label: 'Calificación',
                color: textMuted,
              ),
              const SizedBox(width: 24),
              Stat(
                icon: Icons.rate_review_outlined,
                value: '${musician.reviewsCount}',
                label: 'Reseñas',
                color: textMuted,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: border, height: 1),
        ],
      ),
    );
  }
}
