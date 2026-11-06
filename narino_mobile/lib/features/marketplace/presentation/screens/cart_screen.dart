import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/tienda_ui.dart';

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

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Vaciar el carrito?'),
        content: const Text('Se quitarán todas las obras que agregaste.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tomate,
              foregroundColor: Colors.black,
            ),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final done = await ref.read(cartProvider.notifier).clearCart();
    if (!mounted) return;
    _snack(done
        ? 'Carrito vaciado.'
        : ref.read(cartProvider).errorMessage ?? 'No se pudo vaciar.');
  }

  Future<void> _remove(CartItemModel item) async {
    final ok = await ref.read(cartProvider.notifier).removeFromCart(item.obraId);
    if (!mounted) return;
    _snack(ok
        ? '"${item.obraTitulo}" salió del carrito.'
        : ref.read(cartProvider).errorMessage ?? 'No se pudo quitar.');
  }

  Future<void> _checkout() async {
    if (_creatingOrder) return;
    setState(() => _creatingOrder = true);
    try {
      final order = await ref.read(ordersProvider.notifier).createOrder();
      if (!mounted) return;
      if (order == null) {
        _snack(ref.read(ordersProvider).errorMessage ??
            'No se pudo crear la orden.');
        return;
      }
      context.push('/marketplace/checkout?orderId=${order.id}');
    } finally {
      if (mounted) setState(() => _creatingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final state = ref.watch(cartProvider);
    final noDisponibles = state.items.where((i) => !i.disponible).toList();
    final comprables = state.items.where((i) => i.disponible).toList();
    // Solo suma lo que realmente se puede pagar.
    final total = comprables.fold<double>(0, (s, i) => s + i.precio);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu carrito'),
        actions: [
          if (state.itemCount > 0)
            IconButton(
              tooltip: 'Vaciar carrito',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? ListView(
                  children: [
                    NcEmptyState(
                      icon: Icons.shopping_bag_outlined,
                      accent: nc.tienda,
                      title: 'Tu carrito está vacío',
                      message: 'Cuando una obra te enamore, agrégala aquí y '
                          'págala de forma segura.',
                      actionLabel: 'Explorar la tienda',
                      onAction: () => context.go('/marketplace'),
                      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(cartProvider.notifier).loadCart(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      if (noDisponibles.isNotEmpty) ...[
                        NcBanner(
                          accent: nc.oroA,
                          icon: Icons.info_outline_rounded,
                          message: noDisponibles.length == 1
                              ? 'Una obra ya no está disponible. Quítala para '
                                  'continuar con el pago.'
                              : '${noDisponibles.length} obras ya no están '
                                  'disponibles. Quítalas para continuar.',
                        ),
                        const SizedBox(height: 14),
                      ],
                      for (final item in state.items) ...[
                        _ItemCard(item: item, onRemove: () => _remove(item)),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
      bottomNavigationBar: state.items.isEmpty
          ? null
          : NcGlassBottomBar(
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comprables.length == 1
                            ? '1 obra'
                            : '${comprables.length} obras',
                        style: AppTypography.bodySmall(color: nc.textSecondary),
                      ),
                      Text(formatCOP(total),
                          style: AppTypography.price(color: nc.tienda.ink)
                              .copyWith(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NcPrimaryButton(
                      label: 'Continuar al pago',
                      icon: Icons.lock_outline_rounded,
                      loading: _creatingOrder,
                      onPressed: noDisponibles.isEmpty ? _checkout : null,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onRemove});

  final CartItemModel item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return NcCard(
      padding: const EdgeInsets.all(12),
      gradientBorder: false,
      onTap: () => context.push('/artworks/${item.obraId}'),
      child: Row(
        children: [
          Opacity(
            opacity: item.disponible ? 1 : 0.45,
            child: ObraThumb(url: item.imagenUrl, size: 76),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.obraTitulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSemiBold(color: nc.textPrimary)),
                if (item.artistaNombre.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.artistaNombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(color: nc.textSecondary)),
                ],
                const SizedBox(height: 8),
                item.disponible
                    ? Text(formatCOP(item.precio),
                        style: AppTypography.labelSemiBold(color: nc.tienda.ink)
                            .copyWith(fontWeight: FontWeight.w800))
                    : NcStatusPill(
                        label: 'Ya no disponible',
                        accent: nc.tomateA,
                        icon: Icons.block_rounded,
                      ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar del carrito',
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, color: nc.textSecondary),
          ),
        ],
      ),
    );
  }
}
