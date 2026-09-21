import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/musician_model.dart';
import 'follow_detail_button.dart';
import 'profile_stats.dart';
import 'small_placeholder.dart';

class MusicianSliverAppBar extends ConsumerWidget {
  const MusicianSliverAppBar({
    super.key,
    required this.musician,
    required this.isDark,
  });

  final MusicianModel musician;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.obsidiana,
      foregroundColor: AppColors.oroClaro,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            musician.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: musician.coverUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.indigoNoche,
                    ),
                  )
                : Container(color: AppColors.indigoNoche),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: musician.photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: musician.photoUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const SmallPlaceholder(),
                          )
                        : const SmallPlaceholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                musician.name,
                                style: AppTypography.displaySemiBold(
                                    color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (musician.isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.verified,
                                    size: 16,
                                    color: AppColors.indigoClaro),
                              ),
                          ],
                        ),
                        if (musician.city != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 2),
                              Text(musician.city!,
                                  style: AppTypography.caption(
                                      color: Colors.white70)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  FollowDetailButton(musician: musician),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: ProfileStats(
          musician: musician,
          textPrimary: textPrimary,
          textMuted: textMuted,
          isDark: isDark,
        ),
      ),
    );
  }
}
