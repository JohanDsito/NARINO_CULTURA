import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/user_role_provider.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/artwork_model.dart';

class ActionButton extends ConsumerWidget {
  const ActionButton({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (artwork.estado != 'disponible' || artwork.precio == null) {
      return const SizedBox.shrink();
    }

    final role = ref.watch(currentUserRoleProvider).value;
    if (role == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Carrito disponible próximamente')),
          );
        },
        icon: const Icon(Icons.shopping_cart_outlined),
        label: Text(
          'Agregar al carrito',
          style: AppTypography.labelSemiBold(color: Colors.white),
        ),
      ),
    );
  }
}
