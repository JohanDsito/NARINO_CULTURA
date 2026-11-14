import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../domain/artwork_model.dart';
import '../catalog_screen/artwork_card.dart' show formatPrecioCOP;

/// Chips de categoría/estado, título, vistas y precio.
class DetailHeader extends StatelessWidget {
  const DetailHeader({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final (String estado, NcAccent estadoAccent) = switch (artwork.estado) {
      'en_subasta' => ('En subasta', nc.subastas),
      'vendida' => ('Vendida', nc.tomateA),
      _ => ('Disponible', nc.successA),
    };

    Widget pill(String text, NcAccent a, {bool filled = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: filled ? a.fill : a.tint,
            borderRadius: BorderRadius.circular(99),
            border: filled
                ? null
                : Border.all(color: a.fill.withValues(alpha: 0.4)),
          ),
          child: Text(
            text,
            style: AppTypography.caption(color: filled ? a.onFill : a.ink)
                .copyWith(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (artwork.categoria.isNotEmpty)
              pill(artwork.categoria, nc.catalogo),
            pill(estado, estadoAccent, filled: artwork.estado != 'disponible'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_outlined, size: 15, color: nc.textMuted),
                const SizedBox(width: 4),
                Text(
                  artwork.viewsCount == 1
                      ? '1 vista'
                      : '${artwork.viewsCount} vistas',
                  style: AppTypography.bodySmall(color: nc.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Semantics(
          header: true,
          child: Text(
            artwork.titulo,
            style: AppTypography.displayBlack(color: nc.textPrimary)
                .copyWith(fontSize: 28, height: 1.12),
          ),
        ),
        const SizedBox(height: 10),
        if (artwork.precio != null)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatPrecioCOP(artwork.precio!),
                  style: AppTypography.price(color: nc.tienda.ink)
                      .copyWith(fontSize: 26),
                ),
                TextSpan(
                  text: '  COP',
                  style: AppTypography.labelMedium(color: nc.textSecondary),
                ),
              ],
            ),
          )
        else
          Text('Obra en exhibición — no está a la venta',
              style: AppTypography.bodyMedium(color: nc.textSecondary)),
      ],
    );
  }
}
