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
        obraTitulo: json['title']?.toString() ??
            json['obra_titulo']?.toString() ??
            '',
        artistaNombre: json['artista_nombre']?.toString() ?? '',
        estado: json['estado']?.toString() ?? 'disponible',
        precio: json['precio'] != null
            ? double.tryParse(json['precio'].toString())
            : null,
        imagenUrl: json['imagen_url']?.toString(),
      );

  bool get isDisponible => estado == 'disponible';
  bool get isVendida => estado == 'vendida';
  bool get isEnSubasta => estado == 'en_subasta';
}
