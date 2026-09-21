import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../artworks/domain/artwork_model.dart';
import 'image_placeholder.dart';

class ArtworkCard extends StatelessWidget {
  const ArtworkCard({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppColors.bgCardDark : AppColors.bgCardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return GestureDetector(
      onTap: () => context.push('/artworks/${artwork.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              child: artwork.imagenes.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: artwork.imagenes.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        color: isDark
                            ? AppColors.bgSubtleDark
                            : AppColors.bgSubtleLight,
                      ),
                      errorWidget: (_, __, ___) => ImagePlaceholder(
                          isDark: isDark),
                    )
                  : ImagePlaceholder(isDark: isDark),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.titulo,
                    style: AppTypography.labelSemiBold(color: textPrimary)
                        .copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (artwork.precio != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '\$${artwork.precio!.toStringAsFixed(0)}',
                      style: AppTypography.caption(
                              color: AppColors.indigoClaro)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text('No disponible',
                        style: AppTypography.caption(color: textMuted)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
