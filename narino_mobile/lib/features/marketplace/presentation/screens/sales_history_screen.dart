import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/order_model.dart';
import '../providers/cart_provider.dart';
import 'sales_history_screen/error_view.dart';
import 'sales_history_screen/sales_body.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _salesHistoryProvider = FutureProvider<List<OrderModel>>((ref) async {
  return ref.read(marketplaceRepositoryProvider).getSalesHistory();
});

// ─── Pantalla principal ───────────────────────────────────────────────────────

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrders = ref.watch(_salesHistoryProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Mis ventas',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: asyncOrders.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2),
        ),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (orders) => SalesBody(orders: orders),
      ),
    );
  }
}
