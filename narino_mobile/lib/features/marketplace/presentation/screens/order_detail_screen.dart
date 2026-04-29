import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/order_model.dart';
import '../providers/orders_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Orden #$orderId',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: orderAsync.when(
        data: (order) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(order: order),
            const SizedBox(height: 12),
            ...order.items.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: ListTile(
                    leading: i.imagenUrl == null
                        ? Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.bgSubtleLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              i.imagenUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.bgSubtleLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                    title: Text(
                      i.obraTitulo,
                      style: AppTypography.labelSemiBold(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: Text(
                      i.artistaNombre,
                      style: AppTypography.caption(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                    trailing: Text(
                      _fmt(i.precio),
                      style: AppTypography.labelSemiBold(
                        color: AppColors.indigoNoche,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (order.isPendiente)
              FilledButton.icon(
                onPressed: () async {
                  final url = await ref
                      .read(ordersProvider.notifier)
                      .initiatePayment(order.id);
                  if (!context.mounted) return;
                  if (url == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ref.read(ordersProvider).errorMessage ?? 'Error',
                        ),
                      ),
                    );
                    return;
                  }
                  final uri = Uri.tryParse(url);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.indigoNoche,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                icon: const Icon(Icons.credit_card),
                label: const Text('Pagar'),
              ),
          ],
        ),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: AppTypography.bodyMedium(color: AppColors.textMutedLight),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  String _fmt(double value) {
    final n = value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Estado: ${order.estado}',
                  style: AppTypography.labelSemiBold(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              if (order.comprobantePdfUrl != null)
                IconButton(
                  tooltip: 'Comprobante (PDF)',
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  color: AppColors.textMutedLight,
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
          const SizedBox(height: 6),
          Text(
            'Total: ${order.totalFormateado}',
            style: AppTypography.labelSemiBold(color: AppColors.indigoNoche),
          ),
        ],
      ),
    );
  }
}
