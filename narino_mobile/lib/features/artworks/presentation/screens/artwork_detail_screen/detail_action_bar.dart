import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../marketplace/presentation/providers/cart_provider.dart';
import '../../../domain/artwork_model.dart';
import '../catalog_screen/artwork_card.dart' show formatPrecioCOP;

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
                        style:
                            AppTypography.bodySmall(color: nc.textSecondary)),
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
