import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).loadCart();
    });
  }

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
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final ok = await ref.read(cartProvider.notifier).clearCart();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Carrito vaciado.'
            : (ref.read(cartProvider).errorMessage ?? 'Error')),
      ),
    );
  }

  Future<void> _goCheckout() async {
    if (_creatingOrder) return;
    setState(() => _creatingOrder = true);
    try {
      final order = await ref.read(ordersProvider.notifier).createOrder();
      if (!mounted) return;
      if (order == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(ordersProvider).errorMessage ?? 'Error'),
          ),
        );
        return;
      }
      context.push('/marketplace/checkout?orderId=${order.id}');
    } finally {
      if (mounted) setState(() => _creatingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
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
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.textMutedLight,
                        size: 64,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tu carrito está vacío.',
                        style: AppTypography.bodyMedium(
                          color: AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => context.go('/catalog'),
                        child: const Text('Ver catálogo'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _CartItemCard(
                    item: state.items[index],
                    onRemove: () async {
                      final ok = await ref
                          .read(cartProvider.notifier)
                          .removeFromCart(state.items[index].id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Eliminado del carrito.'
                                : (ref.read(cartProvider).errorMessage ??
                                    'Error'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.bgCardLight,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
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
                      style: AppTypography.caption(
                          color: AppColors.textMutedLight),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.totalFormateado,
                      style: AppTypography.labelSemiBold(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: state.itemCount == 0
                    ? null
                    : _creatingOrder
                        ? null
                        : _goCheckout,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.indigoNoche,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                child: _creatingOrder
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ir al checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item, required this.onRemove});

  final CartItemModel item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 96,
              height: 96,
              child: item.imagenUrl == null
                  ? Container(color: AppColors.bgSubtleLight)
                  : Image.network(
                      item.imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.bgSubtleLight),
                    ),
            ),
          ),
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
                    style: AppTypography.labelSemiBold(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.artistaNombre,
                    style:
                        AppTypography.caption(color: AppColors.textMutedLight),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.precioFormateado,
                    style: AppTypography.labelSemiBold(
                        color: AppColors.indigoNoche),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
            color: AppColors.textMutedLight,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}
