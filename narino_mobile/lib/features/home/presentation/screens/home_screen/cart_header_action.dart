import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/widgets/design/design.dart';
import '../../../../marketplace/presentation/providers/cart_provider.dart';

class CartHeaderAction extends ConsumerWidget {
  const CartHeaderAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider.select((s) => s.items.length));
    return NcIconButton(
      icon: Icons.shopping_bag_outlined,
      tooltip: 'Carrito',
      badge: count,
      onPressed: () => context.push('/marketplace/cart'),
    );
  }
}
