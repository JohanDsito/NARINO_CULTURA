import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'item_thumb.dart';

// ─── Fila de ítem de la orden ─────────────────────────────────────────────────

class OrderItemRow extends StatelessWidget {
  const OrderItemRow({super.key, required this.item});

  final dynamic item; // OrderItemModel

  String _fmt(double value) {
    final n = value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }

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
    final indigoFg = isDark ? AppColors.indigoDark : AppColors.indigoNoche;

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ItemThumb(imageUrl: item.imagenUrl),
        ),
        title: Text(
          item.obraTitulo,
          style: AppTypography.labelSemiBold(color: textPrimary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            item.artistaNombre,
            style: AppTypography.caption(color: textMuted),
          ),
        ),
        trailing: Text(
          _fmt(item.precio),
          style: AppTypography.labelSemiBold(color: indigoFg),
        ),
      ),
    );
  }
}
