/// Modelo de dominio que representa una obra marcada como favorita por el usuario.
class FavoriteModel {
  const FavoriteModel({
    required this.id,
    required this.obraId,
    required this.obraTitulo,
    required this.artistaNombre,
    required this.estado,
    this.precio,
    this.imagenUrl,
  });

  final String id;
  final String obraId;
  final String obraTitulo;
  final String artistaNombre;
  final String estado;
  final double? precio;
  final String? imagenUrl;

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => FavoriteModel(
        id: json['id']?.toString() ?? '',
        obraId: json['artwork_id']?.toString() ??
            json['artwork']?.toString() ??
            json['obra_id']?.toString() ??
            '',
        obraTitulo: json['artwork_title']?.toString() ??
            json['title']?.toString() ??
            json['obra_titulo']?.toString() ??
            '',
        artistaNombre: json['artist_name']?.toString() ??
            json['artista_nombre']?.toString() ??
            '',
        estado: (json['artwork_status']?.toString() ??
                json['status']?.toString() ??
                json['estado']?.toString() ??
                'disponible')
            .toLowerCase(),
        precio: json['artwork_price'] != null
            ? double.tryParse(json['artwork_price'].toString())
            : json['price'] != null
            ? double.tryParse(json['price'].toString())
            : json['precio'] != null
                ? double.tryParse(json['precio'].toString())
                : null,
        imagenUrl: _nonEmpty(json['artwork_image_url']) ??
            _nonEmpty(json['main_image_url']) ??
            _nonEmpty(json['imagen_url']),
      );

  static String? _nonEmpty(Object? v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  bool get isDisponible => estado == 'disponible';
  bool get isVendida => estado == 'vendida';
  bool get isEnSubasta => estado == 'en_subasta';
}
