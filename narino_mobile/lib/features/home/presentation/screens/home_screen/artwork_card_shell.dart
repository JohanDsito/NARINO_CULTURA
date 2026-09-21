import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class ArtworkCardShell extends StatelessWidget {
  const ArtworkCardShell({
    required this.title,
    required this.artist,
    required this.price,
    this.imageUrl,
    required this.onTap,
    super.key,
  });

  final String title;
  final String artist;
  final String price;
  final String? imageUrl;
  final VoidCallback? onTap;

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
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final pillBg = isDark
        ? AppColors.oroAndino.withValues(alpha: 0.22)
        : AppColors.oroPalido;
    final pillFg = isDark ? cs.onSurface : AppColors.obsidiana;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de la obra
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 78,
                width: double.infinity,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: bgSubtle,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: textMuted,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: bgSubtle,
                          child: Icon(
                            Icons.image_outlined,
                            color: textMuted,
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        color: bgSubtle,
                        child: Icon(
                          Icons.image_outlined,
                          color: textMuted,
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTypography.labelSemiBold(color: textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              artist,
              style: AppTypography.bodySmall(color: textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    price,
                    style: AppTypography.labelSemiBold(color: cs.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Ver',
                    style: AppTypography.caption(color: pillFg),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
