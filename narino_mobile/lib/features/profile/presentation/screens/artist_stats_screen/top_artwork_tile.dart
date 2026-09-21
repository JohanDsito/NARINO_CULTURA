import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'top_artwork.dart';

class TopArtworkTile extends StatelessWidget {
  const TopArtworkTile({super.key, required this.artwork});

  final TopArtwork artwork;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: InkWell(
        onTap: artwork.id == null
            ? null
            : () => context.push('/artworks/${artwork.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: artwork.imageUrl == null
                    ? Container(
                        width: 54,
                        height: 54,
                        color: bgSubtle,
                        child: Icon(
                          Icons.image_outlined,
                          color: textMuted,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: artwork.imageUrl!,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        placeholder: (context, _) => Container(
                          width: 54,
                          height: 54,
                          color: bgSubtle,
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, _, __) => Container(
                          width: 54,
                          height: 54,
                          color: bgSubtle,
                          child: Icon(
                            Icons.image_outlined,
                            color: textMuted,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.title ?? 'Obra',
                      style: AppTypography.labelSemiBold(
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${artwork.visits} visitas',
                      style: AppTypography.bodySmall(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
