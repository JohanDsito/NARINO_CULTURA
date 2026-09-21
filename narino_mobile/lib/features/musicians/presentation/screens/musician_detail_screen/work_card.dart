import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/musician_model.dart';
import 'work_placeholder.dart';

class WorkCard extends StatelessWidget {
  const WorkCard({super.key, required this.work, required this.isDark});

  final MusicalWorkModel work;
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: work.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: work.coverUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        WorkPlaceholder(isDark: isDark),
                  )
                : WorkPlaceholder(isDark: isDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(work.title,
                    style: AppTypography.labelSemiBold(color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (work.genre != null)
                  Text(work.genre!,
                      style: AppTypography.caption(color: AppColors.indigoClaro),
                      maxLines: 1),
                if (work.year != null)
                  Text('${work.year}',
                      style: AppTypography.caption(color: textMuted)),
              ],
            ),
          ),
          if (work.audioUrl != null)
            const Icon(Icons.play_circle_outline,
                color: AppColors.indigoClaro, size: 28),
        ],
      ),
    );
  }
}
