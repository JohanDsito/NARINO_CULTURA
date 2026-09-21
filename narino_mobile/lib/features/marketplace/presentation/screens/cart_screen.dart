import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';
import 'cart_screen/cart_body.dart';
import 'cart_screen/cart_bottom_bar.dart';

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
      body: CartBody(
        state: state,
        onRemove: _removeItem,
      ),
      bottomSheet: CartBottomBar(
        totalFormateado: state.totalFormateado,
        itemCount: state.itemCount,
        creatingOrder: _creatingOrder,
        onCheckout: _goCheckout,
      ),
    );
  }
}

