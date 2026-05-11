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

  final int id;
  final int obraId;
  final String obraTitulo;
  final String artistaNombre;
  final String estado;
  final double? precio;
  final String? imagenUrl;

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => FavoriteModel(
        id: json['id'],
        obraId: json['obra_id'],
        obraTitulo: json['obra_titulo'],
        artistaNombre: json['artista_nombre'],
        estado: json['estado'] ?? 'disponible',
        precio:
            json['precio'] != null ? double.tryParse(json['precio'].toString()) : null,
        imagenUrl: json['imagen_url'],
      );

  bool get isDisponible => estado == 'disponible';
  bool get isVendida => estado == 'vendida';
  bool get isEnSubasta => estado == 'en_subasta';
}
