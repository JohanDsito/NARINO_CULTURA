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

  String get precioFormateado {
    final n = precio
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        obraId:
            json['artwork']?.toString() ?? json['obra_id']?.toString() ?? '',
        obraTitulo: json['artwork_title']?.toString() ??
            json['obra_titulo']?.toString() ??
            '',
        artistaNombre: json['artist_name']?.toString() ??
            json['artista_nombre']?.toString() ??
            '',
        precio: double.tryParse(
              (json['price'] ?? json['precio'] ?? 0).toString(),
            ) ??
            0,
        imagenUrl: _nonEmpty(json['artwork_image_url']) ??
            _nonEmpty(json['imagen_url']),
      );
}

String? _nonEmpty(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}
