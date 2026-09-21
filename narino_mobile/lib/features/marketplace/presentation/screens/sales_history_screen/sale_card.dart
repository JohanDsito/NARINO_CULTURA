import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/order_model.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// ─── Tarjeta de venta ─────────────────────────────────────────────────────────

class SaleCard extends StatelessWidget {
  const SaleCard({super.key, required this.order});

  final OrderModel order;

  ({Color bg, Color fg}) _getEstadoColors(bool isDark) => switch (order.estado) {
        'completado' => (bg: AppColors.selvaPalida, fg: AppColors.selvaAndina),
        'pendiente' => (bg: AppColors.oroPalido, fg: AppColors.oroAndino),
        'fallido' => (bg: AppColors.error.withAlpha(10), fg: AppColors.error),
        _ => (
            bg: isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
            fg: isDark ? AppColors.textMutedDark : AppColors.textMutedLight
          ),
      };

  String get _estadoLabel => switch (order.estado) {
        'completado' => 'Completado',
        'pendiente' => 'Pendiente',
        'fallido' => 'Fallido',
        'reembolsado' => 'Reembolsado',
        _ => order.estado,
      };

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

    final colors = _getEstadoColors(isDark);

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Orden #${order.id}',
                  style: AppTypography.labelSemiBold(color: textPrimary),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _estadoLabel,
                  style: AppTypography.caption(color: colors.fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _fmtDate(order.creadoEn),
            style: AppTypography.caption(color: textMuted),
          ),
          const SizedBox(height: 10),

          // ── Obras ────────────────────────────────────────────────────
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

          // ── Total ─────────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 14, color: textMuted),
              const SizedBox(width: 5),
              Text(
                order.totalFormateado,
                style: AppTypography.labelSemiBold(color: indigoFg),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
