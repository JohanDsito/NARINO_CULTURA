import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/orders_provider.dart';
import 'checkout_screen/checkout_item_row.dart';
import 'checkout_screen/payment_footer.dart';
import 'checkout_screen/security_banner.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _submitting = false;

  // ─── Pago ─────────────────────────────────────────────────────────────────

  Future<void> _pay() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final url = await ref
          .read(ordersProvider.notifier)
          .initiatePayment(widget.orderId);

      if (!mounted) return;

      if (url == null) {
        _showSnackBar(
            ref.read(ordersProvider).errorMessage ?? 'Error al iniciar pago');
        return;
      }

      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (!mounted) return;

      ref.read(ordersProvider.notifier).startPaymentPolling(
            orderId: widget.orderId,
            onEstado: (estado) {
              if (!mounted) return;
              final isTerminal = estado == 'completado' ||
                  estado == 'fallido' ||
                  estado == 'reembolsado';
              if (!isTerminal) return;

              ref.read(ordersProvider.notifier).stopPaymentPolling();
              context.go(
                '/marketplace/payment-result?orderId=${widget.orderId}'
                '&success=${estado == "completado"}',
              );
            },
            interval: const Duration(seconds: 5),
          );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Checkout',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: orderAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2),
        ),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: AppTypography.bodyMedium(color: textMuted)),
        ),
        data: (order) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner de seguridad ──────────────────────────────────────
            const SecurityBanner(),

            // ── Encabezado del resumen ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Resumen del pedido',
                style: AppTypography.labelSemiBold(color: textPrimary),
              ),
            ),

            // ── Lista de ítems de la orden ───────────────────────────────
            Expanded(
              child: order.items.isEmpty
                  ? Center(
                      child: Text(
                        'No hay ítems en esta orden.',
                        style: AppTypography.bodyMedium(color: textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: order.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          CheckoutItemRow(item: order.items[i]),
                    ),
            ),

            // ── Total y botón de pago ────────────────────────────────────
            PaymentFooter(
              totalFormateado: order.totalFormateado,
              itemCount: order.items.length,
              submitting: _submitting,
              onPay: _pay,
            ),
          ],
        ),
      ),
    );
  }
}
