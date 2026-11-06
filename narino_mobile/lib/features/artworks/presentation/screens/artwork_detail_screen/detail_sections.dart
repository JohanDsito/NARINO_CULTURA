import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../marketplace/presentation/providers/cart_provider.dart';
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
            border: filled ? null : Border.all(color: a.fill.withValues(alpha: 0.4)),
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
            if (artwork.categoria.isNotEmpty) pill(artwork.categoria, nc.catalogo),
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

/// Artista con anillo de serpentina y acceso a su perfil.
class ArtistTile extends StatelessWidget {
  const ArtistTile({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final inicial = artwork.artistaNombre.isNotEmpty
        ? artwork.artistaNombre.characters.first.toUpperCase()
        : '?';
    final foto = artwork.artistaFoto;
    return NcCard(
      padding: const EdgeInsets.all(14),
      onTap: artwork.artistaSlug.isEmpty
          ? null
          : () => context.push('/artistas/${artwork.artistaSlug}'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                ...nc.carnavalGradient.colors,
                nc.carnavalGradient.colors.first,
              ]),
            ),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: nc.bgCard,
              backgroundImage: (foto != null && foto.isNotEmpty)
                  ? CachedNetworkImageProvider(foto)
                  : null,
              child: (foto == null || foto.isEmpty)
                  ? Text(inicial,
                      style: AppTypography.displaySemiBold(
                          color: nc.catalogo.ink))
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CREADA POR',
                    style: AppTypography.caption(color: nc.textMuted)
                        .copyWith(letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text(
                  artwork.artistaNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSemiBold(color: nc.textPrimary)
                      .copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          if (artwork.artistaSlug.isNotEmpty) ...[
            Text('Ver perfil',
                style: AppTypography.labelMedium(color: nc.azul)
                    .copyWith(fontWeight: FontWeight.w600)),
            Icon(Icons.chevron_right_rounded, color: nc.azul),
          ],
        ],
      ),
    );
  }
}

/// Ficha técnica en grilla de 2 columnas con íconos.
class FactsGrid extends StatelessWidget {
  const FactsGrid({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final facts = <(IconData, String, String, NcAccent)>[
      if (artwork.categoria.isNotEmpty)
        (Icons.category_outlined, 'Categoría', artwork.categoria, nc.catalogo),
      if ((artwork.tecnica ?? '').isNotEmpty)
        (Icons.brush_outlined, 'Técnica', artwork.tecnica!, nc.naranjaA),
      if ((artwork.dimensiones ?? '').isNotEmpty)
        (Icons.straighten_rounded, 'Dimensiones', artwork.dimensiones!,
            nc.azulA),
      if (artwork.anio != null)
        (Icons.event_outlined, 'Año', '${artwork.anio}', nc.oroA),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ficha técnica',
            style: AppTypography.displaySemiBold(color: nc.textPrimary)),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final w = (c.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final f in facts)
                SizedBox(
                  width: w,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: nc.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: nc.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(f.$1, size: 20, color: f.$4.ink),
                        const SizedBox(height: 10),
                        Text(f.$2,
                            style: AppTypography.bodySmall(
                                color: nc.textSecondary)),
                        const SizedBox(height: 2),
                        Text(f.$3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSemiBold(
                                    color: nc.textPrimary)
                                .copyWith(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

/// Descripción con "Ver más".
class DescriptionBlock extends StatefulWidget {
  const DescriptionBlock({super.key, required this.text});

  final String text;

  @override
  State<DescriptionBlock> createState() => _DescriptionBlockState();
}

class _DescriptionBlockState extends State<DescriptionBlock> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final largo = widget.text.length > 220;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sobre la obra',
            style: AppTypography.displaySemiBold(color: nc.textPrimary)),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
          child: Text(
            widget.text,
            maxLines: _open || !largo ? null : 5,
            overflow: _open || !largo ? null : TextOverflow.ellipsis,
            style: AppTypography.bodyLarge(color: nc.textSecondary)
                .copyWith(fontSize: 15),
          ),
        ),
        if (largo)
          TextButton(
            onPressed: () => setState(() => _open = !_open),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(_open ? 'Ver menos' : 'Ver más'),
          ),
      ],
    );
  }
}

/// Barra inferior fija con la acción principal según el estado de la obra.
class DetailActionBar extends ConsumerStatefulWidget {
  const DetailActionBar({
    super.key,
    required this.artwork,
    required this.canManage,
    required this.isLoggedIn,
  });

  final ArtworkModel artwork;
  final bool canManage;
  final bool isLoggedIn;

  @override
  ConsumerState<DetailActionBar> createState() => _DetailActionBarState();
}

class _DetailActionBarState extends ConsumerState<DetailActionBar> {
  bool _adding = false;

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    final ok =
        await ref.read(cartProvider.notifier).addToCart(widget.artwork.id);
    if (!mounted) return;
    setState(() => _adding = false);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? '¡Agregada a tu carrito!'
          : ref.read(cartProvider).errorMessage ??
              'No se pudo agregar al carrito.'),
      action: ok
          ? SnackBarAction(
              label: 'Ver carrito',
              onPressed: () => context.push('/marketplace/cart'),
            )
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = widget.artwork;
    final enCarrito = ref.watch(
        cartProvider.select((s) => s.items.any((i) => i.obraId == a.id)));

    final Widget action;
    if (widget.canManage) {
      action = NcSecondaryButton(
        label: 'Editar obra',
        icon: Icons.edit_outlined,
        onPressed: () => context.push('/artworks/${a.id}/edit'),
      );
    } else if (a.estado == 'en_subasta') {
      action = NcPrimaryButton(
        label: 'Ir a subastas',
        icon: Icons.gavel_rounded,
        onPressed: () => context.go('/auctions'),
      );
    } else if (a.estado == 'vendida') {
      action = NcBanner(
        accent: nc.tomateA,
        icon: Icons.sell_outlined,
        message: 'Esta obra ya encontró hogar. Explora otras del artista.',
      );
    } else if (a.precio == null || !widget.isLoggedIn) {
      return const SizedBox.shrink();
    } else if (enCarrito) {
      action = NcSecondaryButton(
        label: 'Ya está en tu carrito · Ver',
        icon: Icons.shopping_bag_outlined,
        onPressed: () => context.push('/marketplace/cart'),
      );
    } else {
      action = NcPrimaryButton(
        label: 'Agregar al carrito',
        icon: Icons.add_shopping_cart_rounded,
        loading: _adding,
        onPressed: _addToCart,
      );
    }

    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
          decoration: BoxDecoration(
            color: nc.bgGlass,
            border: Border(top: BorderSide(color: nc.border)),
          ),
          child: Row(
            children: [
              if (a.precio != null &&
                  a.estado == 'disponible' &&
                  !widget.canManage) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Precio',
                        style: AppTypography.bodySmall(color: nc.textSecondary)),
                    Text(formatPrecioCOP(a.precio!),
                        style: AppTypography.price(color: nc.tienda.ink)
                            .copyWith(fontSize: 19)),
                  ],
                ),
                const SizedBox(width: 16),
              ],
              Expanded(child: action),
            ],
          ),
        ),
      ),
    );
  }
}
