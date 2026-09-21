import 'package:flutter/material.dart';

import 'cart_item_card.dart';
import 'empty_cart.dart';

class CartBody extends StatelessWidget {
  const CartBody({super.key, required this.state, required this.onRemove});

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
      return const EmptyCart();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => CartItemCard(
        item: state.items[i],
        onRemove: () => onRemove(state.items[i].obraId),
      ),
    );
  }
}
