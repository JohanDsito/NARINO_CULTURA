import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../marketplace/presentation/providers/favorites_provider.dart';
import '../../../domain/artwork_model.dart';

String formatPrecioCOP(double value) {
  final raw = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  return '\$$raw';
}

/// Tarjeta de obra del catálogo: imagen protagonista, insignia de estado,
/// corazón de favorito en vidrio y precio en naranja.
class CatalogArtworkCard extends ConsumerWidget {
  const CatalogArtworkCard({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final image = artwork.imagenes.isNotEmpty ? artwork.imagenes.first : null;

    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nc.magentaA.tint, nc.naranjaA.tint],
        ),
      ),
      child: Center(
        child: Icon(Icons.palette_outlined, color: nc.catalogo.ink, size: 30),
      ),
    );

    final (String? badge, NcAccent? badgeAccent) = switch (artwork.estado) {
      'en_subasta' => ('En subasta', nc.subastas),
      'vendida' => ('Vendida', nc.tomateA),
      _ => (null, null),
    };

    return NcPressable(
      onTap: () => context.push('/artworks/${artwork.id}'),
      pressedScale: 0.97,
      semanticLabel: '${artwork.titulo}, de ${artwork.artistaNombre}'
          '${artwork.precio != null ? ', ${formatPrecioCOP(artwork.precio!)}' : ''}'
          '${badge != null ? ', $badge' : ''}',
      child: Container(
        decoration: BoxDecoration(
          color: nc.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: nc.border),
          boxShadow: nc.isDark ? nc.shadow : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null)
                    CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => fallback,
                      errorWidget: (_, __, ___) => fallback,
                    )
                  else
                    fallback,
                  if (badge != null)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeAccent!.fill,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          badge,
                          style: AppTypography.caption(color: badgeAccent.onFill)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _FavoriteButton(artwork: artwork),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSemiBold(color: nc.textPrimary)
                        .copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artwork.artistaNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(color: nc.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artwork.precio != null
                        ? formatPrecioCOP(artwork.precio!)
                        : 'En exhibición',
                    maxLines: 1,
                    style: artwork.precio != null
                        ? AppTypography.labelSemiBold(color: nc.tienda.ink)
                            .copyWith(fontWeight: FontWeight.w800, fontSize: 14)
                        : AppTypography.bodySmall(color: nc.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final isFav = ref.watch(favoritesProvider).isFavorite(artwork.id);
    return Semantics(
      button: true,
      toggled: isFav,
      label: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
      excludeSemantics: true,
      child: NcPressable(
        onTap: () =>
            ref.read(favoritesProvider.notifier).toggleFavorite(artwork.id),
        pressedScale: 0.85,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.32),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  key: ValueKey(isFav),
                  size: 20,
                  color: isFav ? nc.magenta : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
