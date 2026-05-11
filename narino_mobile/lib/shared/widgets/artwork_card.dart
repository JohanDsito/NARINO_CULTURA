import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/artworks/domain/artwork_model.dart';

class ArtworkCard extends StatelessWidget {
  const ArtworkCard({super.key, required this.artwork, this.compact = false});

  final ArtworkModel artwork;
  final bool compact;

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
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final priceColor = isDark ? AppColors.indigoDark : AppColors.indigoNoche;
    final imageUrl =
        artwork.imagenes.isNotEmpty ? artwork.imagenes.first : null;

    return GestureDetector(
      onTap: () => context.go('/artworks/${artwork.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: compact ? 4 : 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, _) => Container(
                        color: bgSubtle,
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, _, __) => Container(
                        color: bgSubtle,
                        child: Icon(
                          Icons.image_outlined,
                          color: textMuted,
                          size: 32,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: bgSubtle,
                      child: Icon(
                        Icons.palette_outlined,
                        color: textMuted,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: compact ? 3 : 2,
              child: Padding(
                padding: EdgeInsets.all(compact ? 8 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.titulo,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSemiBold(
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artwork.artistaNombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(
                        color: textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      artwork.precio == null
                          ? 'Precio a consultar'
                          : _fmt(artwork.precio!),
                      style: AppTypography.caption(color: priceColor)
                          .copyWith(fontSize: compact ? 11 : null),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double value) {
    final n = value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }
}
