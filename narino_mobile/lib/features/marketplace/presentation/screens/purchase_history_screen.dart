import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/order_model.dart';
import '../providers/cart_provider.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _purchaseHistoryProvider = FutureProvider<List<OrderModel>>((ref) async {
  return ref.read(marketplaceRepositoryProvider).getPurchaseHistory();
});

// ─── Constantes ───────────────────────────────────────────────────────────────

const _kFiltros = [
  'todos',
  'completado',
  'pendiente',
  'fallido',
  'reembolsado'
];

String _labelFiltro(String v) => switch (v) {
      'completado' => 'Completado',
      'pendiente' => 'Pendiente',
      'fallido' => 'Fallido',
      'reembolsado' => 'Reembolsado',
      _ => 'Todos',
    };

({Color bg, Color fg}) _estadoColors(String estado) => switch (estado) {
      'completado' => (bg: AppColors.selvaPalida, fg: AppColors.selvaAndina),
      'pendiente' => (bg: AppColors.oroPalido, fg: AppColors.oroAndino),
      'fallido' => (bg: AppColors.error.withAlpha(10), fg: AppColors.error),
      'reembolsado' => (
          bg: AppColors.bgSubtleLight,
          fg: AppColors.textMutedLight
        ),
      _ => (bg: AppColors.bgSubtleLight, fg: AppColors.textMutedLight),
    };

String _fmtDate(DateTime d) =>
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
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.tierraProfunda, strokeWidth: 2),
        ),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (orders) {
          final filtered = _estadoFiltro == 'todos'
              ? orders
              : orders.where((o) => o.estado == _estadoFiltro).toList();

          return Column(
            children: [
              _FilterChips(
                selected: _estadoFiltro,
                onSelect: (v) => setState(() => _estadoFiltro = v),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyOrders()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _OrderCard(order: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Filtros ──────────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _kFiltros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _kFiltros[i];
          final isSelected = selected == f;
          return FilterChip(
            label: Text(
              _labelFiltro(f),
              style: AppTypography.caption(
                color: isSelected
                    ? AppColors.tierraProfunda
                    : AppColors.textMutedLight,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelect(f),
            backgroundColor: AppColors.bgSubtleLight,
            selectedColor: AppColors.tierraPalida,
            checkmarkColor: Colors.transparent,
            side: BorderSide(
              color:
                  isSelected ? AppColors.tierraProfunda : AppColors.borderLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99),
            ),
          );
        },
      ),
    );
  }
}

// ─── Estados vacíos y de error ────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 56, color: AppColors.borderLight),
          const SizedBox(height: 14),
          Text(
            'No hay compras para este filtro.',
            style: AppTypography.bodyMedium(color: AppColors.textMutedLight),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.textMutedLight),
            const SizedBox(height: 14),
            Text(
              message,
              style: AppTypography.bodyMedium(color: AppColors.textMutedLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tarjeta de orden ─────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final colors = _estadoColors(order.estado);
    final label = _labelFiltro(order.estado);

    return InkWell(
      onTap: () => context.go('/marketplace/order/${order.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Orden #${order.id}',
                    style: AppTypography.labelSemiBold(
                        color: AppColors.textPrimaryLight),
                  ),
                ),
                _StatusBadge(label: label, colors: colors),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              _fmtDate(order.creadoEn),
              style: AppTypography.caption(color: AppColors.textMutedLight),
            ),
            const SizedBox(height: 10),

            // ── Ítems ────────────────────────────────────────────────
            ...order.items.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record,
                        size: 6, color: AppColors.textMutedLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        i.obraTitulo,
                        style: AppTypography.bodySmall(
                            color: AppColors.textMutedLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Footer ───────────────────────────────────────────────
            Row(
              children: [
                Text(
                  order.totalFormateado,
                  style:
                      AppTypography.labelSemiBold(color: AppColors.indigoNoche),
                ),
                const Spacer(),
                if (order.isCompletado && order.comprobantePdfUrl != null)
                  _ReceiptButton(url: order.comprobantePdfUrl!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge de estado ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.colors,
  });

  final String label;
  final ({Color bg, Color fg}) colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTypography.caption(color: colors.fg),
      ),
    );
  }
}

// ─── Botón de comprobante ─────────────────────────────────────────────────────

class _ReceiptButton extends StatelessWidget {
  const _ReceiptButton({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
      label: const Text('Comprobante'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.tierraProfunda,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 32),
      ),
    );
  }
}
