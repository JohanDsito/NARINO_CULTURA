import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../providers/orders_provider.dart';
import '../widgets/tienda_ui.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text('Orden ${codigoOrden(orderId)}')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [
          NcEmptyState(
            icon: Icons.cloud_off_rounded,
            accent: nc.tomateA,
            title: 'No pudimos cargar la orden',
            message: e.toString(),
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(orderDetailProvider(orderId)),
          ),
        ]),
        data: (order) {
          final accent = estadoOrdenAccent(nc, order.estado);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              NcCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    NcAccentIcon(
                      icon: estadoOrdenIcon(order.estado),
                      accent: accent,
                      size: 52,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(estadoOrdenLabel(order.estado),
                              style: AppTypography.displaySemiBold(
                                  color: accent.ink)),
                          const SizedBox(height: 2),
                          Text('Creada el ${fechaCorta(order.creadoEn)}',
                              style: AppTypography.bodySmall(
                                  color: nc.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Obras en esta orden',
                  style: AppTypography.displaySemiBold(color: nc.textPrimary)),
              const SizedBox(height: 12),
              for (final item in order.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NcCard(
                    padding: const EdgeInsets.all(12),
                    gradientBorder: false,
                    onTap: () => context.push('/artworks/${item.obraId}'),
                    child: Row(
                      children: [
                        ObraThumb(url: item.imagenUrl, size: 60),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.obraTitulo,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSemiBold(
                                      color: nc.textPrimary)),
                              if (item.artistaNombre.isNotEmpty)
                                Text(item.artistaNombre,
                                    style: AppTypography.bodySmall(
                                        color: nc.textSecondary)),
                            ],
                          ),
                        ),
                        Text(formatCOP(item.precio),
                            style: AppTypography.labelSemiBold(
                                color: nc.tienda.ink)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              NcCard(
                padding: const EdgeInsets.all(16),
                gradientBorder: false,
                child: Row(
                  children: [
                    Text('Total',
                        style:
                            AppTypography.labelSemiBold(color: nc.textPrimary)),
                    const Spacer(),
                    Text(formatCOP(order.total),
                        style: AppTypography.price(color: nc.tienda.ink)),
                  ],
                ),
              ),
              if (order.isCompletado && order.comprobantePdfUrl != null) ...[
                const SizedBox(height: 16),
                NcSecondaryButton(
                  label: 'Descargar comprobante',
                  icon: Icons.receipt_long_outlined,
                  onPressed: () => launchUrl(
                      Uri.parse(order.comprobantePdfUrl!),
                      mode: LaunchMode.externalApplication),
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: orderAsync.valueOrNull?.isPendiente == true
          ? NcGlassBottomBar(
              child: NcPrimaryButton(
                label: 'Completar pago',
                icon: Icons.credit_card_rounded,
                onPressed: () =>
                    context.push('/marketplace/checkout?orderId=$orderId'),
              ),
            )
          : null,
    );
  }
}
