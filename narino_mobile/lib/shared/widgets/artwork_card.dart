import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/nc_theme.dart';
import '../../features/artworks/domain/artwork_model.dart';
import 'design/nc_pressable.dart';

/// Tarjeta de obra para grillas: la imagen ocupa el espacio libre y la
/// información se ajusta a su contenido (no se desborda con textos largos).
class ArtworkCard extends StatelessWidget {
  const ArtworkCard({super.key, required this.artwork, this.compact = false});

  final ArtworkModel artwork;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final imageUrl =
        artwork.imagenes.isNotEmpty ? artwork.imagenes.first : null;

    Widget fallback(IconData icon) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                nc.tomate.withValues(alpha: 0.18),
                nc.azul.withValues(alpha: 0.18),
              ],
            ),
          ),
          child: Center(child: Icon(icon, color: nc.textSecondary, size: 32)),
        );

    return NcPressable(
      onTap: () => context.push('/artworks/${artwork.id}'),
      pressedScale: 0.97,
      semanticLabel: '${artwork.titulo}, de ${artwork.artistaNombre}',
      child: Container(
        decoration: BoxDecoration(
          color: nc.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: nc.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => fallback(Icons.image_outlined),
                      errorWidget: (_, __, ___) =>
                          fallback(Icons.image_outlined),
                    )
                  else
                    fallback(Icons.palette_outlined),
                  if (artwork.estado == 'vendida')
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _Badge(label: 'Vendida', accent: nc.tomateA),
                    )
                  else if (artwork.estado == 'en_subasta')
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _Badge(label: 'En subasta', accent: nc.subastas),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 10 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    artwork.titulo,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSemiBold(color: nc.textPrimary)
                        .copyWith(fontSize: compact ? 13 : 14, height: 1.25),
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
                    artwork.precio == null
                        ? 'Precio a consultar'
                        : _fmt(artwork.precio!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSemiBold(color: nc.tienda.ink)
                        .copyWith(
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.accent});
  final String label;
  final NcAccent accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.fill,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTypography.caption(color: accent.onFill)
            .copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
