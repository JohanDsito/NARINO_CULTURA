import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/order_model.dart';
import 'empty_sales.dart';
import 'sale_card.dart';
import 'sales_summary_card.dart';

// ─── Cuerpo principal ─────────────────────────────────────────────────────────

class SalesBody extends StatelessWidget {
  const SalesBody({super.key, required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    final now = DateTime.now();
    final completadas = orders.where((o) => o.isCompletado).toList();

    final totalMes = completadas
        .where(
            (o) => o.creadoEn.year == now.year && o.creadoEn.month == now.month)
        .fold<double>(0, (s, o) => s + o.total);

    final totalHistorico = completadas.fold<double>(0, (s, o) => s + o.total);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        SalesSummaryCard(
          totalMes: totalMes,
          totalHistorico: totalHistorico,
          completadasCount: completadas.length,
        ),
        const SizedBox(height: 18),
        if (orders.isEmpty)
          const EmptySales()
        else ...[
          Text(
            '${orders.length} ${orders.length == 1 ? 'venta' : 'ventas'}',
            style: AppTypography.bodySmall(color: textMuted),
          ),
          const SizedBox(height: 10),
          ...orders.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SaleCard(order: o),
            ),
          ),
        ],
      ],
    );
  }
}
