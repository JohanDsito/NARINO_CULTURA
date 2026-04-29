class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.obraId,
    required this.obraTitulo,
    required this.artistaNombre,
    required this.precio,
    this.imagenUrl,
  });

  final int id;
  final int obraId;
  final String obraTitulo;
  final String artistaNombre;
  final double precio;
  final String? imagenUrl;

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
        id: json['id'],
        obraId: json['obra_id'],
        obraTitulo: json['obra_titulo'],
        artistaNombre: json['artista_nombre'],
        precio: double.tryParse(json['precio'].toString()) ?? 0,
        imagenUrl: json['imagen_url'],
      );

  String get precioFormateado {
    final n = precio
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }
}
