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
  });

  final String id;
  final String estado;
  final double total;
  final DateTime creadoEn;
  final List<OrderItemModel> items;
  final String? comprobantePdfUrl;
  final String? wompiPaymentUrl;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id']?.toString() ?? json['order_id']?.toString() ?? '',
        estado: json['status']?.toString() ??
            json['estado']?.toString() ??
            'pendiente',
        total: double.tryParse(
              (json['total_amount'] ?? json['total'] ?? 0).toString(),
            ) ??
            0,
        creadoEn: DateTime.tryParse(
                json['created_at']?.toString() ??
                    json['creado_en']?.toString() ??
                    '') ??
            DateTime.now(),
        items: (json['items'] as List? ?? [])
            .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        comprobantePdfUrl: json['comprobante_pdf_url']?.toString(),
        wompiPaymentUrl: json['wompi_payment_url']?.toString(),
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

class OrderItemModel {
  const OrderItemModel({
    required this.obraId,
    required this.obraTitulo,
    required this.artistaNombre,
    required this.precio,
    this.imagenUrl,
  });

  final String obraId;
  final String obraTitulo;
  final String artistaNombre;
  final double precio;
  final String? imagenUrl;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        obraId: json['artwork']?.toString() ??
            json['obra_id']?.toString() ??
            '',
        obraTitulo: json['artwork_title']?.toString() ??
            json['obra_titulo']?.toString() ??
            '',
        artistaNombre: json['artista_nombre']?.toString() ?? '',
        precio: double.tryParse(
              (json['price'] ?? json['precio'] ?? 0).toString(),
            ) ??
            0,
        imagenUrl: json['imagen_url']?.toString(),
      );
}
