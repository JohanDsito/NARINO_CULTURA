import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../domain/order_model.dart';
import '../../widgets/tienda_ui.dart';

class CheckoutLinea extends StatelessWidget {
  const CheckoutLinea({super.key, required this.item});

  final OrderItemModel item;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ObraThumb(url: item.imagenUrl, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.obraTitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSemiBold(color: nc.textPrimary)
                        .copyWith(fontSize: 14)),
                if (item.artistaNombre.isNotEmpty)
                  Text(item.artistaNombre,
                      style: AppTypography.bodySmall(color: nc.textSecondary)),
              ],
            ),
          ),
          Text(formatCOP(item.precio),
              style: AppTypography.labelSemiBold(color: nc.textPrimary)
                  .copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}
