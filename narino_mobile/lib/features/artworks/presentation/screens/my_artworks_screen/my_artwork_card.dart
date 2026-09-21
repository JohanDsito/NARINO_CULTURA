import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/artwork_model.dart';

class MyArtworkCard extends StatelessWidget {
  const MyArtworkCard({
    super.key,
    required this.artwork,
    required this.onDelete,
  });

  final ArtworkModel artwork;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final bgSubtle =
        isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;

    return GestureDetector(
      onTap: () => context.push('/artworks/${artwork.id}'),
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
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen
                  artwork.imagenes.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: artwork.imagenes.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: bgSubtle,
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: bgSubtle,
                            child: Icon(
                              Icons.image_outlined,
                              color: textMuted,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          color: bgSubtle,
                          child: Icon(
                            Icons.palette_outlined,
                            color: textMuted,
                            size: 32,
                          ),
                        ),

                  // Badge de estado
                  if (artwork.estado != 'disponible')
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: artwork.estado == 'en_subasta'
                              ? (isDark
                                  ? AppColors.indigoDark
                                  : AppColors.indigoNoche)
                              : bgSubtle,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          artwork.estado == 'en_subasta'
                              ? 'En subasta'
                              : 'Vendida',
                          style: AppTypography.caption(
                            color: artwork.estado == 'en_subasta'
                                ? Colors.white
                                : textMuted,
                          ),
                        ),
                      ),
                    ),

                  // Botón eliminar
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.88),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info de la obra
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.titulo,
                      style: AppTypography.labelSemiBold(color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artwork.categoria,
                      style: AppTypography.caption(color: textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    artwork.precio != null
                        ? Text(
                            _formatCOP(artwork.precio!),
                            style: AppTypography.labelSemiBold(
                                color: AppColors.oroAndino),
                          )
                        : Text(
                            'Exhibición',
                            style: AppTypography.caption(color: textMuted),
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
}

String _formatCOP(double value) {
  final raw = value.toStringAsFixed(0);
  return '\$${raw.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  )}';
}
