import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/order_model.dart';
import '../providers/cart_provider.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _salesHistoryProvider = FutureProvider<List<OrderModel>>((ref) async {
  return ref.read(marketplaceRepositoryProvider).getSalesHistory();
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _fmtCOP(double value) {
  final n = value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  return '\$$n COP';
}

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
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (orders) => _SalesBody(orders: orders),
      ),
    );
  }
}

// ─── Cuerpo principal ─────────────────────────────────────────────────────────

class _SalesBody extends StatelessWidget {
  const _SalesBody({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    final now = DateTime.now();
    final completadas = orders.where((o) => o.isCompletado).toList();

    final totalMes = completadas
        .where(
            (o) => o.creadoEn.year == now.year && o.creadoEn.month == now.month)
        .fold<double>(0, (s, o) => s + o.total);

    final totalHistorico = completadas.fold<double>(0, (s, o) => s + o.total);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _SalesSummaryCard(
          totalMes: totalMes,
          totalHistorico: totalHistorico,
          completadasCount: completadas.length,
        ),
        const SizedBox(height: 18),
        if (orders.isEmpty)
          const _EmptySales()
        else ...[
          Text(
            '${orders.length} ${orders.length == 1 ? 'venta' : 'ventas'}',
            style: AppTypography.bodySmall(color: textMuted),
          ),
          const SizedBox(height: 10),
          ...orders.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SaleCard(order: o),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Card de resumen ──────────────────────────────────────────────────────────

class _SalesSummaryCard extends StatelessWidget {
  const _SalesSummaryCard({
    required this.totalMes,
    required this.totalHistorico,
    required this.completadasCount,
  });

  final double totalMes;
  final double totalHistorico;
  final int completadasCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.obsidiana,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de ventas',
            style:
                AppTypography.caption(color: AppColors.oroClaro.withAlpha(70)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Este mes',
                  value: _fmtCOP(totalMes),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.oroClaro.withAlpha(20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryStat(
                  label: 'Total histórico',
                  value: _fmtCOP(totalHistorico),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.oroClaro.withAlpha(20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryStat(
                  label: 'Completadas',
                  value: '$completadasCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption(color: AppColors.oroClaro.withAlpha(60)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.labelSemiBold(color: AppColors.oroClaro),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Tarjeta de venta ─────────────────────────────────────────────────────────

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.order});

  final OrderModel order;

  ({Color bg, Color fg}) _getEstadoColors(bool isDark) => switch (order.estado) {
        'completado' => (bg: AppColors.selvaPalida, fg: AppColors.selvaAndina),
        'pendiente' => (bg: AppColors.oroPalido, fg: AppColors.oroAndino),
        'fallido' => (bg: AppColors.error.withAlpha(10), fg: AppColors.error),
        _ => (
            bg: isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
            fg: isDark ? AppColors.textMutedDark : AppColors.textMutedLight
          ),
      };

  String get _estadoLabel => switch (order.estado) {
        'completado' => 'Completado',
        'pendiente' => 'Pendiente',
        'fallido' => 'Fallido',
        'reembolsado' => 'Reembolsado',
        _ => order.estado,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final indigoFg = isDark ? AppColors.indigoDark : AppColors.indigoNoche;

    final colors = _getEstadoColors(isDark);

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Orden #${order.id}',
                  style: AppTypography.labelSemiBold(color: textPrimary),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _estadoLabel,
                  style: AppTypography.caption(color: colors.fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _fmtDate(order.creadoEn),
            style: AppTypography.caption(color: textMuted),
          ),
          const SizedBox(height: 10),

          // ── Obras ────────────────────────────────────────────────────
          ...order.items.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Icon(Icons.fiber_manual_record, size: 6, color: textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      i.obraTitulo,
                      style: AppTypography.bodySmall(color: textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Total ─────────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 14, color: textMuted),
              const SizedBox(width: 5),
              Text(
                order.totalFormateado,
                style: AppTypography.labelSemiBold(color: indigoFg),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptySales extends StatelessWidget {
  const _EmptySales();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 48),
          Icon(Icons.storefront_outlined, size: 56, color: iconColor),
          const SizedBox(height: 14),
          Text(
            'Aún no tienes ventas.',
            style: AppTypography.bodyMedium(color: textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Vista de error ───────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: textMuted),
            const SizedBox(height: 14),
            Text(
              message,
              style: AppTypography.bodyMedium(color: textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
