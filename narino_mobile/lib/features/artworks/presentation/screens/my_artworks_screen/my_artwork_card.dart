import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/artwork_model.dart';
import '../catalog_screen/artwork_card.dart' show formatPrecioCOP;

/// Tarjeta de una obra propia con menú de acciones (editar, subastar,
/// eliminar). Subastar y eliminar solo aplican a obras disponibles.
class MyArtworkCard extends StatelessWidget {
  const MyArtworkCard({
    super.key,
    required this.artwork,
    required this.onEdit,
    required this.onAuction,
    required this.onDelete,
  });

  final ArtworkModel artwork;
  final VoidCallback onEdit;
  final VoidCallback onAuction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final image = artwork.imagenes.isNotEmpty ? artwork.imagenes.first : null;
    final disponible = artwork.estado == 'disponible';
    final (String label, NcAccent accent) = switch (artwork.estado) {
      'en_subasta' => ('En subasta', nc.subastas),
      'vendida' => ('Vendida', nc.tomateA),
      _ => ('Disponible', nc.successA),
    };

    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nc.magentaA.tint, nc.naranjaA.tint],
        ),
      ),
      child: Center(
          child:
              Icon(Icons.palette_outlined, color: nc.catalogo.ink, size: 30)),
    );

    return NcPressable(
      onTap: () => context.push('/artworks/${artwork.id}'),
      pressedScale: 0.97,
      semanticLabel: '${artwork.titulo}, $label',
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
                  if (image != null)
                    CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => fallback,
                      errorWidget: (_, __, ___) => fallback,
                    )
                  else
                    fallback,
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.fill,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(label,
                          style: AppTypography.caption(color: accent.onFill)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: _Menu(
                      disponible: disponible,
                      onEdit: onEdit,
                      onAuction: onAuction,
                      onDelete: onDelete,
                    ),
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
                  Text(artwork.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSemiBold(color: nc.textPrimary)
                          .copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.visibility_outlined,
                          size: 13, color: nc.textMuted),
                      const SizedBox(width: 4),
                      Text('${artwork.viewsCount}',
                          style:
                              AppTypography.bodySmall(color: nc.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artwork.precio != null
                        ? formatPrecioCOP(artwork.precio!)
                        : 'En exhibición',
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

class _Menu extends StatelessWidget {
  const _Menu({
    required this.disponible,
    required this.onEdit,
    required this.onAuction,
    required this.onDelete,
  });

  final bool disponible;
  final VoidCallback onEdit;
  final VoidCallback onAuction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.black.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          child: PopupMenuButton<String>(
            tooltip: 'Opciones de la obra',
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
            onSelected: (v) => switch (v) {
              'edit' => onEdit(),
              'auction' => onAuction(),
              'delete' => onDelete(),
              _ => null,
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar'),
                ),
              ),
              if (disponible)
                PopupMenuItem(
                  value: 'auction',
                  child: ListTile(
                    leading: Icon(Icons.gavel_rounded, color: nc.subastas.ink),
                    title: const Text('Subastar'),
                  ),
                ),
              if (disponible)
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded,
                        color: nc.tomateA.ink),
                    title: Text('Eliminar',
                        style: TextStyle(color: nc.tomateA.ink)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
