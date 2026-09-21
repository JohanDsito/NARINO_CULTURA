import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/order_model.dart';
import '../purchase_history_screen.dart'
    show estadoColors, fmtDate, labelFiltro;
import 'receipt_button.dart';
import 'status_badge.dart';

// ─── Tarjeta de orden ─────────────────────────────────────────────────────────

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final OrderModel order;

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

    final colors = estadoColors(order.estado, isDark);
    final label = labelFiltro(order.estado);

    return InkWell(
      onTap: () => context.push('/marketplace/order/${order.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Orden #${order.id}',
                    style: AppTypography.labelSemiBold(color: textPrimary),
                  ),
                ),
                StatusBadge(label: label, colors: colors),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              fmtDate(order.creadoEn),
              style: AppTypography.caption(color: textMuted),
            ),
            const SizedBox(height: 10),

            // ── Ítems ────────────────────────────────────────────────
            ...order.items.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Icon(Icons.fiber_manual_record, size: 6, color: textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        i.obraTitulo,
                        style: AppTypography.bodySmall(color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Footer ───────────────────────────────────────────────
            Row(
              children: [
                Text(
                  order.totalFormateado,
                  style: AppTypography.labelSemiBold(color: indigoFg),
                ),
                const Spacer(),
                if (order.isCompletado && order.comprobantePdfUrl != null)
                  ReceiptButton(url: order.comprobantePdfUrl!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
