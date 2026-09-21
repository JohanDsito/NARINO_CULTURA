import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/musician_model.dart';
import 'avatar_placeholder.dart';
import 'follow_button.dart';

// ─── MusicianCard (shared widget) ────────────────────────────────────────────

class MusicianCard extends ConsumerWidget {
  const MusicianCard({super.key, required this.musician});

  final MusicianModel musician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return GestureDetector(
      onTap: () => context.push('/musicians/${musician.slug}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: musician.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: musician.photoUrl!,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => AvatarPlaceholder(
                        isDark: isDark,
                      ),
                    )
                  : AvatarPlaceholder(isDark: isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          musician.name,
                          style: AppTypography.labelSemiBold(color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (musician.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            size: 14,
                            color: AppColors.indigoClaro,
                          ),
                        ),
                    ],
                  ),
                  if (musician.city != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: textMuted),
                        const SizedBox(width: 2),
                        Text(
                          musician.city!,
                          style: AppTypography.caption(color: textMuted),
                        ),
                      ],
                    ),
                  ],
                  if (musician.genres.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: musician.genres.take(3).map((g) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.indigoClaro.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            g,
                            style: AppTypography.caption(
                                color: AppColors.indigoClaro),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 13, color: textMuted),
                      const SizedBox(width: 3),
                      Text(
                        '${musician.followersCount}',
                        style: AppTypography.caption(color: textMuted),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.star_outline, size: 13, color: textMuted),
                      const SizedBox(width: 3),
                      Text(
                        musician.averageRating.toStringAsFixed(1),
                        style: AppTypography.caption(color: textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FollowButton(musician: musician),
          ],
        ),
      ),
    );
  }
}
