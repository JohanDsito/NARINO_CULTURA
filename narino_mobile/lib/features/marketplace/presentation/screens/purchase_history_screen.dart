import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/order_model.dart';
import '../providers/cart_provider.dart';

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
    final future = ref.watch(_purchaseHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Compras',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: future.when(
        data: (orders) {
          final filtered = _estadoFiltro == 'todos'
              ? orders
              : orders.where((o) => o.estado == _estadoFiltro).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in const [
                      'todos',
                      'completado',
                      'pendiente',
                      'fallido',
                      'reembolsado',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          selected: _estadoFiltro == f,
                          label: Text(_labelFiltro(f)),
                          onSelected: (_) => setState(() => _estadoFiltro = f),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      'No hay compras para este filtro.',
                      style: AppTypography.bodyMedium(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ),
                )
              else
                for (final order in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderCard(order: order),
                  ),
            ],
          );
        },
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

  String _labelFiltro(String v) {
    switch (v) {
      case 'completado':
        return 'Completado';
      case 'pendiente':
        return 'Pendiente';
      case 'fallido':
        return 'Fallido';
      case 'reembolsado':
        return 'Reembolsado';
      default:
        return 'Todos';
    }
  }
}

final _purchaseHistoryProvider = FutureProvider<List<OrderModel>>((ref) async {
  return ref.read(marketplaceRepositoryProvider).getPurchaseHistory();
});

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final badge = _badge(order.estado);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: InkWell(
        onTap: () => context.go('/marketplace/order/${order.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Orden #${order.id}',
                      style: AppTypography.labelSemiBold(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: badge.color.withAlpha(18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(
                      badge.label,
                      style: AppTypography.caption(color: badge.color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _fmtDate(order.creadoEn),
                style: AppTypography.caption(color: AppColors.textMutedLight),
              ),
              const SizedBox(height: 10),
              ...order.items.map(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${i.obraTitulo}',
                    style: AppTypography.bodySmall(
                        color: AppColors.textMutedLight),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.totalFormateado,
                      style: AppTypography.labelSemiBold(
                        color: AppColors.indigoNoche,
                      ),
                    ),
                  ),
                  if (order.isCompletado && order.comprobantePdfUrl != null)
                    TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(order.comprobantePdfUrl!);
                        if (uri != null) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Comprobante'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({String label, Color color}) _badge(String estado) {
    switch (estado) {
      case 'completado':
        return (label: 'Completado', color: Colors.green);
      case 'pendiente':
        return (label: 'Pendiente', color: Colors.orange);
      case 'fallido':
        return (label: 'Fallido', color: Colors.red);
      case 'reembolsado':
        return (label: 'Reembolsado', color: Colors.grey);
      default:
        return (label: estado, color: AppColors.textMutedLight);
    }
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }
}
