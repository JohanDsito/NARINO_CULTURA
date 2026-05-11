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

  final int id;
  final String estado;
  final double total;
  final DateTime creadoEn;
  final List<OrderItemModel> items;
  final String? comprobantePdfUrl;
  final String? wompiPaymentUrl;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'],
        estado: json['estado'] ?? 'pendiente',
        total: double.tryParse(json['total'].toString()) ?? 0,
        creadoEn: DateTime.tryParse(json['creado_en']?.toString() ?? '') ??
            DateTime.now(),
        items: (json['items'] as List? ?? [])
            .map((e) => OrderItemModel.fromJson(e))
            .toList(),
        comprobantePdfUrl: json['comprobante_pdf_url'],
        wompiPaymentUrl: json['wompi_payment_url'],
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

  final int obraId;
  final String obraTitulo;
  final String artistaNombre;
  final double precio;
  final String? imagenUrl;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        obraId: json['obra_id'],
        obraTitulo: json['obra_titulo'],
        artistaNombre: json['artista_nombre'],
        precio: double.tryParse(json['precio'].toString()) ?? 0,
        imagenUrl: json['imagen_url'],
      );
}
