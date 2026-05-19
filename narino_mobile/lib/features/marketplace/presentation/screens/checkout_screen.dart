import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(cartProvider.notifier).loadCart(),
    );
  }

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
    final cart = ref.watch(cartProvider);

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner de seguridad ────────────────────────────────────────
          const _SecurityBanner(),

          // ── Encabezado del resumen ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Resumen del pedido',
              style: AppTypography.labelSemiBold(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),

          // ── Lista de ítems ─────────────────────────────────────────────
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Text(
                      'No hay items en el carrito.',
                      style: AppTypography.bodyMedium(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _CheckoutItemRow(item: cart.items[i]),
                  ),
          ),

          // ── Total y botón de pago ──────────────────────────────────────
          _PaymentFooter(
            totalFormateado: cart.totalFormateado,
            itemCount: cart.itemCount,
            submitting: _submitting,
            onPay: _pay,
          ),
        ],
      ),
    );
  }
}

// ─── Banner de seguridad ──────────────────────────────────────────────────────

class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.indigoNoche.withAlpha(6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.indigoNoche.withAlpha(18)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.indigoNoche.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_user_outlined,
                color: AppColors.indigoNoche, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pago 100% seguro con Wompi. Tus datos de tarjeta nunca se almacenan en nuestros servidores.',
              style: AppTypography.bodySmall(color: textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fila de ítem en el resumen ───────────────────────────────────────────────

class _CheckoutItemRow extends StatelessWidget {
  const _CheckoutItemRow({required this.item});

  final dynamic item; // CartItemModel

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
    final priceColor = isDark ? AppColors.indigoDark : AppColors.indigoNoche;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.obraTitulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSemiBold(color: textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  item.artistaNombre,
                  style: AppTypography.caption(color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.precioFormateado,
            style: AppTypography.labelSemiBold(color: priceColor),
          ),
        ],
      ),
    );
  }
}

// ─── Footer de pago ───────────────────────────────────────────────────────────

class _PaymentFooter extends StatelessWidget {
  const _PaymentFooter({
    required this.totalFormateado,
    required this.itemCount,
    required this.submitting,
    required this.onPay,
  });

  final String totalFormateado;
  final int itemCount;
  final bool submitting;
  final VoidCallback onPay;

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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: bgCard,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$itemCount ${itemCount == 1 ? 'obra' : 'obras'}',
                    style: AppTypography.caption(color: textMuted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    totalFormateado,
                    style: AppTypography.labelSemiBold(color: textPrimary),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: (itemCount == 0 || submitting) ? null : onPay,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              icon: submitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.onPrimary),
                    )
                  : const Icon(Icons.credit_card_outlined),
              label: Text(
                submitting ? 'Redirigiendo...' : 'Pagar con Wompi',
                style: AppTypography.labelSemiBold(color: cs.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
