import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/order_model.dart';

export '../../../../core/utils/money.dart' show formatCOP;

/// Código corto y legible de una orden: `#A1B2C3D4` (en vez del UUID).
String codigoOrden(String id) {
  final limpio = id.replaceAll('-', '');
  return '#${(limpio.length > 8 ? limpio.substring(0, 8) : limpio).toUpperCase()}';
}

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// `6 nov 2026`
String fechaCorta(DateTime d) => '${d.day} ${_meses[d.month - 1]} ${d.year}';

/// Etiqueta en lenguaje claro para el estado interno de la orden.
String estadoOrdenLabel(String estado) => switch (estado) {
      'completado' => 'Pagada',
      'pendiente' => 'Pendiente de pago',
      'fallido' => 'Cancelada',
      'reembolsado' => 'Reembolsada',
      _ => 'Pendiente',
    };

NcAccent estadoOrdenAccent(NcColors nc, String estado) => switch (estado) {
      'completado' => nc.successA,
      'pendiente' => nc.oroA,
      'fallido' => nc.tomateA,
      _ => nc.azulA,
    };

IconData estadoOrdenIcon(String estado) => switch (estado) {
      'completado' => Icons.check_circle_rounded,
      'pendiente' => Icons.schedule_rounded,
      'fallido' => Icons.cancel_rounded,
      _ => Icons.replay_rounded,
    };

/// Miniatura cuadrada de obra con respaldo de color.
class ObraThumb extends StatelessWidget {
  const ObraThumb({super.key, required this.url, this.size = 64});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nc.naranjaA.tint, nc.magentaA.tint],
        ),
      ),
      child: Icon(Icons.palette_outlined,
          size: size * 0.38, color: nc.tienda.ink),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SizedBox(
        width: size,
        height: size,
        child: (url == null || url!.isEmpty)
            ? fallback
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}

/// Tarjeta de orden para "Mis compras" y "Mis ventas".
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.esVenta = false});

  final OrderModel order;
  final bool esVenta;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final accent = estadoOrdenAccent(nc, order.estado);
    final items = order.items;
    final titulo = items.isEmpty
        ? 'Orden ${codigoOrden(order.id)}'
        : items.length == 1
            ? items.first.obraTitulo
            : '${items.first.obraTitulo} y ${items.length - 1} más';

    return NcCard(
      padding: const EdgeInsets.all(14),
      gradientBorder: false,
      onTap: () => context.push('/marketplace/order/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 64 + (items.length > 1 ? 14.0 : 0),
                height: 64,
                child: Stack(
                  children: [
                    if (items.length > 1)
                      Positioned(
                        left: 14,
                        child: Opacity(
                          opacity: 0.6,
                          child: ObraThumb(url: items[1].imagenUrl),
                        ),
                      ),
                    ObraThumb(
                        url: items.isNotEmpty ? items.first.imagenUrl : null),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSemiBold(
                            color: nc.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      '${codigoOrden(order.id)} · ${fechaCorta(order.creadoEn)}',
                      style: AppTypography.bodySmall(color: nc.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              NcStatusPill(
                label: esVenta && order.isCompletado
                    ? 'Vendida'
                    : estadoOrdenLabel(order.estado),
                accent: accent,
                icon: estadoOrdenIcon(order.estado),
              ),
              const Spacer(),
              Text(formatCOP(esVenta ? order.montoVenta : order.total),
                  style: AppTypography.price(color: nc.tienda.ink)
                      .copyWith(fontSize: 17)),
            ],
          ),
          if (order.isCompletado && order.comprobantePdfUrl != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => launchUrl(
                    Uri.parse(order.comprobantePdfUrl!),
                    mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Comprobante'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fila de chips para filtrar por estado.
class EstadoFiltroChips extends StatelessWidget {
  const EstadoFiltroChips({
    super.key,
    required this.opciones,
    required this.selected,
    required this.onSelect,
  });

  /// (valor, etiqueta)
  final List<(String, String)> opciones;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: opciones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (valor, label) = opciones[i];
          final sel = valor == selected;
          final accent =
              valor == 'todos' ? nc.tienda : estadoOrdenAccent(nc, valor);
          return ChoiceChip(
            label: Text(label),
            selected: sel,
            showCheckmark: false,
            onSelected: (_) => onSelect(valor),
            selectedColor: accent.fill,
            backgroundColor: nc.bgGlass,
            side: BorderSide(color: sel ? accent.fill : nc.border),
            labelStyle: AppTypography.labelMedium(
                    color: sel ? accent.onFill : nc.textPrimary)
                .copyWith(fontWeight: FontWeight.w600),
          );
        },
      ),
    );
  }
}
