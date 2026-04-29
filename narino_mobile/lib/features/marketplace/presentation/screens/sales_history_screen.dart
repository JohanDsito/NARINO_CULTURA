import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/order_model.dart';
import '../providers/cart_provider.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(_salesHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Ventas',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: future.when(
        data: (orders) {
          final now = DateTime.now();
          final completadas = orders.where((o) => o.isCompletado).toList();
          final mes = completadas.where((o) {
            return o.isCompletado &&
                o.creadoEn.year == now.year &&
                o.creadoEn.month == now.month;
          }).toList();

          final totalMes = mes.fold<double>(0, (s, o) => s + o.total);
          final totalHistorico =
              completadas.fold<double>(0, (s, o) => s + o.total);

          final totalMesFmt = totalMes.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
          final totalHistoricoFmt = totalHistorico
              .toStringAsFixed(0)
              .replaceAllMapped(
                  RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: AppColors.obsidiana,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Este mes',
                            style: AppTypography.caption(
                              color: AppColors.oroClaro.withAlpha(200),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$$totalMesFmt COP',
                            style: AppTypography.labelSemiBold(
                              color: AppColors.oroClaro,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.oroClaro.withAlpha(60),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total histórico',
                            style: AppTypography.caption(
                              color: AppColors.oroClaro.withAlpha(200),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$$totalHistoricoFmt COP',
                            style: AppTypography.labelSemiBold(
                              color: AppColors.oroClaro,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (orders.isEmpty)
                Center(
                  child: Text(
                    'Aún no tienes ventas.',
                    style: AppTypography.bodyMedium(
                      color: AppColors.textMutedLight,
                    ),
                  ),
                )
              else
                ...orders.map(
                  (o) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgCardLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: ListTile(
                        title: Text(
                          'Orden #${o.id}',
                          style: AppTypography.labelSemiBold(
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        subtitle: Text(
                          '${_fmtDate(o.creadoEn)} · ${o.totalFormateado}\n${o.items.map((e) => e.obraTitulo).join(', ')}',
                          style: AppTypography.caption(
                            color: AppColors.textMutedLight,
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ),
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

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }
}

final _salesHistoryProvider = FutureProvider<List<OrderModel>>((ref) async {
  return ref.read(marketplaceRepositoryProvider).getSalesHistory();
});
