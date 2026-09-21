import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/orders_provider.dart';
import 'order_detail_screen/error_view.dart';
import 'order_detail_screen/order_body.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Orden #$orderId',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: orderAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
        ),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (order) => OrderBody(order: order),
      ),
    );
  }
}
