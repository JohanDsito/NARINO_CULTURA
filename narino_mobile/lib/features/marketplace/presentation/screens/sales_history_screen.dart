import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/order_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/tienda_ui.dart';

final _salesHistoryProvider =
    FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final list = await ref.read(marketplaceRepositoryProvider).getSalesHistory();
  return [...list]..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
});

/// Ventas del artista (el backend solo devuelve órdenes pagadas).
class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final async = ref.watch(_salesHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis ventas')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [
          NcEmptyState(
            icon: Icons.cloud_off_rounded,
            accent: nc.tomateA,
            title: 'No pudimos cargar tus ventas',
            message: e.toString(),
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(_salesHistoryProvider),
          ),
        ]),
        data: (orders) {
          final now = DateTime.now();
          final pagadas = orders.where((o) => o.isCompletado).toList();
          final mes = pagadas
              .where((o) =>
                  o.creadoEn.year == now.year && o.creadoEn.month == now.month)
              .fold<double>(0, (s, o) => s + o.total);
          final total = pagadas.fold<double>(0, (s, o) => s + o.total);
          final obras =
              pagadas.fold<int>(0, (s, o) => s + o.items.length);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_salesHistoryProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                NcCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GANADO ESTE MES',
                          style: AppTypography.kicker(color: nc.oroA.ink)),
                      const SizedBox(height: 6),
                      Text(formatCOP(mes),
                          style: AppTypography.displayBlack(
                                  color: nc.tienda.ink)
                              .copyWith(fontSize: 34)),
                      const SizedBox(height: 16),
                      const NcSerpentina(width: double.infinity, height: 3),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _Stat(
                              label: 'Total histórico',
                              value: formatCOP(total),
                              accent: nc.oroA,
                            ),
                          ),
                          Expanded(
                            child: _Stat(
                              label: 'Obras vendidas',
                              value: '$obras',
                              accent: nc.successA,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (orders.isEmpty)
                  NcEmptyState(
                    icon: Icons.trending_up_rounded,
                    accent: nc.oroA,
                    title: 'Tu primera venta está cerca',
                    message: 'Publica obras con buenas fotos y precio claro '
                        'para que el público las encuentre.',
                    actionLabel: 'Publicar una obra',
                    onAction: () => context.push('/artworks/publish'),
                    padding: EdgeInsets.zero,
                  )
                else ...[
                  Text('Historial',
                      style:
                          AppTypography.displaySemiBold(color: nc.textPrimary)),
                  const SizedBox(height: 12),
                  for (final o in orders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OrderCard(order: o, esVenta: true),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final NcAccent accent;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTypography.displaySemiBold(color: accent.ink)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodySmall(color: nc.textSecondary)),
      ],
    );
  }
}
