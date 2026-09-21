import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/order_model.dart';
import '../../providers/orders_provider.dart';
import 'order_header.dart';
import 'order_item_row.dart';

// ─── Cuerpo de la orden ───────────────────────────────────────────────────────

class OrderBody extends ConsumerWidget {
  const OrderBody({super.key, required this.order});

  final OrderModel order;

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final url =
        await ref.read(ordersProvider.notifier).initiatePayment(order.id);

    if (!context.mounted) return;

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              ref.read(ordersProvider).errorMessage ?? 'Error al iniciar pago'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        OrderHeader(order: order),
        const SizedBox(height: 14),
        Text(
          'Obras en esta orden',
          style: AppTypography.labelSemiBold(color: textSecondary),
        ),
        const SizedBox(height: 10),
        ...order.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OrderItemRow(item: item),
          ),
        ),
        if (order.isPendiente) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _pay(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              icon: const Icon(Icons.credit_card_outlined),
              label: Text(
                'Completar pago',
                style: AppTypography.labelSemiBold(color: cs.onPrimary),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
