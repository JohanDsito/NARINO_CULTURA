import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/cart_item_model.dart';
import '../../widgets/tienda_ui.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({super.key, required this.item, required this.onRemove});

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
