import 'order_item_model.dart';

export 'order_item_model.dart';

/// Modelo de dominio que representa una orden de compra/venta en el marketplace.
class OrderModel {
  const OrderModel({
    required this.id,
    required this.estado,
    required this.total,
    required this.creadoEn,
    required this.items,
    this.comprobantePdfUrl,
    this.wompiPaymentUrl,
    this.montoVendedor,
  });

  final String id;
  final String estado;
  final double total;
  final DateTime creadoEn;
  final List<OrderItemModel> items;
  final String? comprobantePdfUrl;
  final String? wompiPaymentUrl;

  /// Solo en "Mis ventas": lo que le corresponde al artista (`seller_amount`).
  /// Si el backend aún no lo envía, es `null` y se usa [total].
  final double? montoVendedor;

  /// Monto a mostrar en una venta.
  double get montoVenta => montoVendedor ?? total;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id']?.toString() ?? json['order_id']?.toString() ?? '',
        estado: switch ((json['status'] ?? json['estado'] ?? 'PENDIENTE')
            .toString()
            .toUpperCase()) {
          'PAGADO' => 'completado',
          'CANCELADO' => 'fallido',
          'REEMBOLSADO' => 'reembolsado',
          _ => 'pendiente',
        },
        total: double.tryParse(
              (json['total_amount'] ?? json['total'] ?? 0).toString(),
            ) ??
            0,
        creadoEn: DateTime.tryParse(json['created_at']?.toString() ??
                json['creado_en']?.toString() ??
                '') ??
            DateTime.now(),
        items: (json['items'] as List? ?? [])
            .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        comprobantePdfUrl: json['comprobante_pdf_url']?.toString(),
        wompiPaymentUrl: json['wompi_payment_url']?.toString(),
        montoVendedor: json['seller_amount'] == null
            ? null
            : double.tryParse(json['seller_amount'].toString()),
      );

  bool get isPendiente => estado == 'pendiente';
  bool get isCompletado => estado == 'completado';
  bool get isFallido => estado == 'fallido';
  bool get isReembolsado => estado == 'reembolsado';

  String get totalFormateado {
    final n = total
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }
}
