/// Modelo de dominio que representa un ítem dentro del carrito de compras.
class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.obraId,
    required this.obraTitulo,
    required this.artistaNombre,
    required this.precio,
    this.imagenUrl,
  });

  final String id;
  final String obraId;
  final String obraTitulo;
  final String artistaNombre;
  final double precio;
  final String? imagenUrl;

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
        id: json['id']?.toString() ?? '',
        obraId: json['obra_id']?.toString() ?? '',
        obraTitulo: json['obra_titulo']?.toString() ?? '',
        artistaNombre: json['artista_nombre']?.toString() ?? '',
        precio: double.tryParse(json['precio'].toString()) ?? 0,
        imagenUrl: json['imagen_url']?.toString(),
      );

  String get precioFormateado {
    final n = precio
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }
}
