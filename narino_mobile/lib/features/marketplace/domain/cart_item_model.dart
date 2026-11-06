/// Modelo de dominio que representa un ítem dentro del carrito de compras.
class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.obraId,
    required this.obraTitulo,
    required this.artistaNombre,
    required this.precio,
    this.imagenUrl,
    this.estadoObra = 'DISPONIBLE',
  });

  final String id;
  final String obraId;
  final String obraTitulo;
  final String artistaNombre;
  final double precio;
  final String? imagenUrl;

  /// Estado de la obra en el backend (`artwork_status`).
  final String estadoObra;

  /// `false` si la obra se vendió o entró a subasta mientras estaba en el carrito.
  bool get disponible => estadoObra.toUpperCase() == 'DISPONIBLE';

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
        id: json['id']?.toString() ?? '',
        obraId: json['artwork']?.toString() ??
            json['obra_id']?.toString() ??
            '',
        obraTitulo: json['artwork_title']?.toString() ??
            json['obra_titulo']?.toString() ??
            '',
        artistaNombre: json['artista_nombre']?.toString() ?? '',
        precio: double.tryParse(
              (json['artwork_price'] ?? json['precio'] ?? 0).toString(),
            ) ??
            0,
        imagenUrl: json['imagen_url']?.toString(),
        estadoObra: json['artwork_status']?.toString() ?? 'DISPONIBLE',
      );

  String get precioFormateado {
    final n = precio
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }
}
