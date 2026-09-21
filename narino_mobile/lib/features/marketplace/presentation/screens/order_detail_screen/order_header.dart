import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/order_model.dart';

// ─── Encabezado de la orden ───────────────────────────────────────────────────

class OrderHeader extends StatelessWidget {
  const OrderHeader({super.key, required this.order});

  final OrderModel order;

  Color _estadoColor(String estado, bool isDark) {
    return switch (estado) {
      'completado' => AppColors.selvaAndina,
      'pendiente' => AppColors.oroAndino,
      'fallido' || 'reembolsado' => AppColors.error,
      _ => isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
    };
  }

  Color _estadoBg(String estado, bool isDark) {
    return switch (estado) {
      'completado' => AppColors.selvaPalida,
      'pendiente' => AppColors.oroPalido,
      _ => isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final indigoFg = isDark ? AppColors.indigoDark : AppColors.indigoNoche;

    final estadoColor = _estadoColor(order.estado, isDark);
    final estadoBg = _estadoBg(order.estado, isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Badge de estado
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  order.estado.toUpperCase(),
                  style: AppTypography.caption(color: estadoColor),
                ),
              ),
              const Spacer(),
              // Botón de comprobante PDF
              if (order.comprobantePdfUrl != null)
                IconButton(
                  tooltip: 'Ver comprobante PDF',
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  color: textMuted,
                  onPressed: () async {
                    final uri = Uri.tryParse(order.comprobantePdfUrl!);
                    if (uri != null) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 16, color: textMuted),
              const SizedBox(width: 6),
              Text(
                'Total: ${order.totalFormateado}',
                style: AppTypography.labelSemiBold(color: indigoFg),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
