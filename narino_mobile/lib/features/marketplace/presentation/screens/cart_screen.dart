import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _creatingOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(cartProvider.notifier).loadCart(),
    );
  }

  // ─── Acciones ─────────────────────────────────────────────────────────────

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Seguro que quieres eliminar todos los items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref.read(cartProvider.notifier).clearCart();
    if (!mounted) return;
    _showSnackBar(
      ok ? 'Carrito vaciado.' : ref.read(cartProvider).errorMessage ?? 'Error',
    );
  }

  Future<void> _removeItem(String itemId) async {
    final ok = await ref.read(cartProvider.notifier).removeFromCart(itemId);
    if (!mounted) return;
    _showSnackBar(
      ok
          ? 'Eliminado del carrito.'
          : ref.read(cartProvider).errorMessage ?? 'Error',
    );
  }

  Future<void> _goCheckout() async {
    if (_creatingOrder) return;
    setState(() => _creatingOrder = true);
    try {
      final order = await ref.read(ordersProvider.notifier).createOrder();
      if (!mounted) return;
      if (order == null) {
        _showSnackBar(ref.read(ordersProvider).errorMessage ?? 'Error');
        return;
      }
      context.push('/marketplace/checkout?orderId=${order.id}');
    } finally {
      if (mounted) setState(() => _creatingOrder = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Carrito',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          if (state.itemCount > 0)
            IconButton(
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Vaciar carrito',
            ),
        ],
      ),
      body: _CartBody(
        state: state,
        onRemove: _removeItem,
      ),
      bottomSheet: _CartBottomBar(
        totalFormateado: state.totalFormateado,
        itemCount: state.itemCount,
        creatingOrder: _creatingOrder,
        onCheckout: _goCheckout,
      ),
    );
  }
}

// ─── Cuerpo del carrito ───────────────────────────────────────────────────────

class _CartBody extends StatelessWidget {
  const _CartBody({required this.state, required this.onRemove});

  final dynamic state; // CartState
  final Future<void> Function(String itemId) onRemove;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (state.items.isEmpty) {
      return _EmptyCart();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _CartItemCard(
        item: state.items[i],
        onRemove: () => onRemove(state.items[i].obraId),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, color: textMuted, size: 64),
          const SizedBox(height: 12),
          Text(
            'Tu carrito está vacío.',
            style: AppTypography.bodyMedium(color: textMuted),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.go('/catalog'),
            icon: const Icon(Icons.palette_outlined, size: 16),
            label: const Text('Ver catálogo'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Barra inferior ───────────────────────────────────────────────────────────

class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar({
    required this.totalFormateado,
    required this.itemCount,
    required this.creatingOrder,
    required this.onCheckout,
  });

  final String totalFormateado;
  final int itemCount;
  final bool creatingOrder;
  final VoidCallback onCheckout;

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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: bgCard,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: AppTypography.caption(color: textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalFormateado,
                    style: AppTypography.labelSemiBold(color: textPrimary),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: (itemCount == 0 || creatingOrder) ? null : onCheckout,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              icon: creatingOrder
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Icon(Icons.shopping_cart_checkout_outlined),
              label: Text(
                creatingOrder ? 'Procesando...' : 'Ir al checkout',
                style: AppTypography.labelSemiBold(color: cs.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tarjeta de ítem ──────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item, required this.onRemove});

  final CartItemModel item;
  final VoidCallback onRemove;

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
    final priceColor = isDark ? AppColors.indigoDark : AppColors.indigoNoche;
    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          // Imagen
          SizedBox(
            width: 96,
            height: 96,
            child: _ItemImage(imageUrl: item.imagenUrl),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.obraTitulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSemiBold(color: textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.artistaNombre,
                    style: AppTypography.caption(color: textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.precioFormateado,
                    style: AppTypography.labelSemiBold(color: priceColor),
                  ),
                ],
              ),
            ),
          ),

          // Botón eliminar
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
            color: textMuted,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return const _ImageFallback();
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => const _ImageFallback(loading: true),
      errorWidget: (_, __, ___) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      color: bgSubtle,
      child: Center(
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.image_outlined, color: textMuted),
      ),
    );
  }
}
