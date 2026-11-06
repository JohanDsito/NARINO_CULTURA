import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/order_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/tienda_ui.dart';

final _purchaseHistoryProvider =
    FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final list =
      await ref.read(marketplaceRepositoryProvider).getPurchaseHistory();
  return [...list]..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
});

const _filtros = <(String, String)>[
  ('todos', 'Todas'),
  ('completado', 'Pagadas'),
  ('pendiente', 'Pendientes'),
  ('fallido', 'Canceladas'),
  ('reembolsado', 'Reembolsadas'),
];

class PurchaseHistoryScreen extends ConsumerStatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  ConsumerState<PurchaseHistoryScreen> createState() =>
      _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends ConsumerState<PurchaseHistoryScreen> {
  String _filtro = 'todos';

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final async = ref.watch(_purchaseHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis compras')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [
          NcEmptyState(
            icon: Icons.cloud_off_rounded,
            accent: nc.tomateA,
            title: 'No pudimos cargar tus compras',
            message: e.toString(),
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(_purchaseHistoryProvider),
          ),
        ]),
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(children: [
              NcEmptyState(
                icon: Icons.receipt_long_outlined,
                accent: nc.tienda,
                title: 'Aún no has comprado obras',
                message: 'Cuando compres, aquí verás el estado del pago y tu '
                    'comprobante.',
                actionLabel: 'Ir a la tienda',
                onAction: () => context.go('/marketplace'),
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
              ),
            ]);
          }
          final visibles = _filtro == 'todos'
              ? orders
              : orders.where((o) => o.estado == _filtro).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_purchaseHistoryProvider),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                EstadoFiltroChips(
                  opciones: _filtros,
                  selected: _filtro,
                  onSelect: (v) => setState(() => _filtro = v),
                ),
                const SizedBox(height: 8),
                if (visibles.isEmpty)
                  NcEmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    accent: nc.azulA,
                    title: 'Nada por aquí',
                    message: 'No tienes compras con este estado.',
                  )
                else
                  for (final o in visibles)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: OrderCard(order: o),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
