import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/cart_item_model.dart';
import 'item_image.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({super.key, required this.item, required this.onRemove});

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
            child: ItemImage(imageUrl: item.imagenUrl),
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
