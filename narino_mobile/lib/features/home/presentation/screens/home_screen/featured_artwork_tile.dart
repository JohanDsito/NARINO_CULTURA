import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../artworks/domain/artwork_model.dart';
import '../home_screen.dart';

class FeaturedArtworkTile extends StatelessWidget {
  const FeaturedArtworkTile({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final image = artwork.imagenes.isNotEmpty ? artwork.imagenes.first : null;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            nc.tomate.withValues(alpha: 0.2),
            nc.azul.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.image_outlined, color: nc.textSecondary, size: 32),
      ),
    );

    return NcPressable(
      onTap: () => context.push('/artworks/${artwork.id}'),
      semanticLabel: '${artwork.titulo}, de ${artwork.artistaNombre}',
      child: SizedBox(
        width: 156,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 156,
              height: 156,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: nc.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: image == null
                  ? fallback
                  : CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => fallback,
                      errorWidget: (_, __, ___) => fallback,
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              artwork.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSemiBold(color: nc.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              artwork.artistaNombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(color: nc.textSecondary),
            ),
            if (artwork.precio != null) ...[
              const SizedBox(height: 4),
              Text(
                formatCOP(artwork.precio!),
                style: AppTypography.labelSemiBold(color: nc.tienda.ink)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
