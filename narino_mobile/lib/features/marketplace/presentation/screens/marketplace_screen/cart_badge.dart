import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Badge del carrito ────────────────────────────────────────────────────────

class CartBadge extends StatelessWidget {
  const CartBadge({super.key, required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined,
              color: AppColors.oroClaro),
          tooltip: 'Carrito',
          onPressed: () => context.push('/marketplace/cart'),
        ),
        if (itemCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  itemCount > 99 ? '99+' : '$itemCount',
                  style: AppTypography.caption(
                    color: Theme.of(context).colorScheme.onError,
                  ).copyWith(fontSize: 9),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
