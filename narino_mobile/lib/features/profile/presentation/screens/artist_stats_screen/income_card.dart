import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../marketplace/domain/order_model.dart';
import '../../../../marketplace/presentation/widgets/tienda_ui.dart';

class IncomeCard extends StatelessWidget {
  const IncomeCard({super.key, required this.ventas});

  final AsyncValue<List<OrderModel>?> ventas;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final lista = ventas.valueOrNull;
    final now = DateTime.now();
    final mes = (lista ?? const <OrderModel>[])
        .where(
            (o) => o.creadoEn.year == now.year && o.creadoEn.month == now.month)
        .fold<double>(0, (s, o) => s + o.montoVenta);
    final total = (lista ?? const <OrderModel>[])
        .fold<double>(0, (s, o) => s + o.montoVenta);

    return NcCard(
      padding: const EdgeInsets.all(18),
      onTap: () => context.push('/marketplace/sales'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NcAccentIcon(
                  icon: Icons.payments_outlined, accent: nc.tienda, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Ingresos de ${_mesNombre(now.month)}',
                    style:
                        AppTypography.labelSemiBold(color: nc.textSecondary)),
              ),
              Icon(Icons.chevron_right_rounded, color: nc.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          if (ventas.isLoading)
            const LinearProgressIndicator()
          else if (lista == null)
            Text('No pudimos cargar tus ventas. Toca para verlas.',
                style: AppTypography.bodySmall(color: nc.textSecondary))
          else ...[
            Text(formatCOP(mes),
                style: AppTypography.displayBold(color: nc.tienda.ink)
                    .copyWith(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              lista.isEmpty
                  ? 'Todavía no tienes ventas pagadas.'
                  : '${formatCOP(total)} en total · '
                      '${lista.length} ${lista.length == 1 ? 'venta' : 'ventas'}',
              style: AppTypography.bodySmall(color: nc.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  static String _mesNombre(int m) => kMesesNombre[m - 1].toLowerCase();
}
