import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../providers/orders_provider.dart';
import '../widgets/tienda_ui.dart';
import 'checkout_screen/checkout_esperando.dart';
import 'checkout_screen/checkout_linea.dart';

/// Tiempo máximo esperando la confirmación de Wompi antes de dejar de
/// consultar (la persona puede volver a verificar manualmente).
const _kMaxEspera = Duration(minutes: 10);

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _submitting = false;
  bool _esperando = false;
  String? _pagoUrl;
  DateTime? _inicioEspera;
  late final OrdersNotifier _orders;

  @override
  void initState() {
    super.initState();
    // Se toma al inicio: en dispose ya no se puede usar `ref`.
    _orders = ref.read(ordersProvider.notifier);
  }

  @override
  void dispose() {
    // Antes el sondeo seguía para siempre aunque se saliera de la pantalla.
    _orders.stopPaymentPolling();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _abrirWompi() async {
    final uri = _pagoUrl == null ? null : Uri.tryParse(_pagoUrl!);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _snack('No se pudo abrir la página de pago.');
  }

  void _esperarConfirmacion() {
    _inicioEspera = DateTime.now();
    setState(() => _esperando = true);
    _orders.startPaymentPolling(
      orderId: widget.orderId,
      interval: const Duration(seconds: 5),
      onEstado: (estado) {
        if (!mounted) {
          _orders.stopPaymentPolling();
          return;
        }
        final terminal = estado == 'completado' ||
            estado == 'fallido' ||
            estado == 'reembolsado';
        if (terminal) {
          _orders.stopPaymentPolling();
          context.go('/marketplace/payment-result?orderId=${widget.orderId}'
              '&success=${estado == 'completado'}');
          return;
        }
        if (DateTime.now().difference(_inicioEspera!) > _kMaxEspera) {
          _orders.stopPaymentPolling();
          setState(() => _esperando = false);
          _snack('Aún no recibimos la confirmación. Puedes verificar más tarde '
              'en "Mis compras".');
        }
      },
    );
  }

  Future<void> _pay() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final url = await _orders.initiatePayment(widget.orderId);
      if (!mounted) return;
      if (url == null) {
        _snack(ref.read(ordersProvider).errorMessage ??
            'No se pudo iniciar el pago.');
        return;
      }
      _pagoUrl = url;
      await _abrirWompi();
      if (mounted) _esperarConfirmacion();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Pagar')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [
          NcEmptyState(
            icon: Icons.cloud_off_rounded,
            accent: nc.tomateA,
            title: 'No pudimos cargar la orden',
            message: e.toString(),
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(orderDetailProvider(widget.orderId)),
          ),
        ]),
        data: (order) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (_esperando) ...[
              const CheckoutEsperando(),
              const SizedBox(height: 16),
            ],
            NcCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Resumen del pedido',
                            style: AppTypography.displaySemiBold(
                                color: nc.textPrimary)),
                      ),
                      Text(codigoOrden(order.id),
                          style:
                              AppTypography.labelMedium(color: nc.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (order.items.isEmpty)
                    Text('Esta orden no tiene obras.',
                        style:
                            AppTypography.bodyMedium(color: nc.textSecondary))
                  else
                    for (final item in order.items) CheckoutLinea(item: item),
                  Divider(height: 28, color: nc.border),
                  Row(
                    children: [
                      Text('Total',
                          style: AppTypography.labelSemiBold(
                              color: nc.textPrimary)),
                      const Spacer(),
                      Text(formatCOP(order.total),
                          style: AppTypography.price(color: nc.tienda.ink)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NcBanner(
              accent: nc.successA,
              icon: Icons.verified_user_outlined,
              message: 'Pago seguro con Wompi. Tus datos de tarjeta nunca se '
                  'guardan en Nariño Cultura.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: orderAsync.valueOrNull == null
          ? null
          : NcGlassBottomBar(
              child: _esperando
                  ? NcSecondaryButton(
                      label: 'Volver a abrir Wompi',
                      icon: Icons.open_in_new_rounded,
                      onPressed: _abrirWompi,
                    )
                  : NcPrimaryButton(
                      label:
                          'Pagar ${formatCOP(orderAsync.valueOrNull!.total)}',
                      icon: Icons.credit_card_rounded,
                      loading: _submitting,
                      onPressed:
                          orderAsync.valueOrNull!.items.isEmpty ? null : _pay,
                    ),
            ),
    );
  }
}
