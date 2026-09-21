import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/order_model.dart';
import '../providers/cart_provider.dart';
import 'purchase_history_screen/empty_orders.dart';
import 'purchase_history_screen/error_view.dart';
import 'purchase_history_screen/filter_chips.dart';
import 'purchase_history_screen/order_card.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _purchaseHistoryProvider = FutureProvider<List<OrderModel>>((ref) async {
  return ref.read(marketplaceRepositoryProvider).getPurchaseHistory();
});

// ─── Constantes ───────────────────────────────────────────────────────────────

const kFiltros = [
  'todos',
  'completado',
  'pendiente',
  'fallido',
  'reembolsado'
];

String labelFiltro(String v) => switch (v) {
      'completado' => 'Completado',
      'pendiente' => 'Pendiente',
      'fallido' => 'Fallido',
      'reembolsado' => 'Reembolsado',
      _ => 'Todos',
    };

({Color bg, Color fg}) estadoColors(String estado, bool isDark) =>
    switch (estado) {
      'completado' => (bg: AppColors.selvaPalida, fg: AppColors.selvaAndina),
      'pendiente' => (bg: AppColors.oroPalido, fg: AppColors.oroAndino),
      'fallido' => (bg: AppColors.error.withAlpha(10), fg: AppColors.error),
      'reembolsado' => (
          bg: isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
          fg: isDark ? AppColors.textMutedDark : AppColors.textMutedLight
        ),
      _ => (
          bg: isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
          fg: isDark ? AppColors.textMutedDark : AppColors.textMutedLight
        ),
    };

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class PurchaseHistoryScreen extends ConsumerStatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  ConsumerState<PurchaseHistoryScreen> createState() =>
      _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends ConsumerState<PurchaseHistoryScreen> {
  String _estadoFiltro = 'todos';

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(_purchaseHistoryProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Mis compras',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: asyncOrders.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2),
        ),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (orders) {
          final filtered = _estadoFiltro == 'todos'
              ? orders
              : orders.where((o) => o.estado == _estadoFiltro).toList();

          return Column(
            children: [
              FilterChips(
                selected: _estadoFiltro,
                onSelect: (v) => setState(() => _estadoFiltro = v),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyOrders()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => OrderCard(order: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
