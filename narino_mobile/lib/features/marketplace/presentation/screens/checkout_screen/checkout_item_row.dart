import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Fila de ítem en el resumen ───────────────────────────────────────────────

class CheckoutItemRow extends StatelessWidget {
  const CheckoutItemRow({super.key, required this.item});

  final dynamic item; // CartItemModel

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
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
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.precioFormateado,
            style: AppTypography.labelSemiBold(color: priceColor),
          ),
        ],
      ),
    );
  }
}
