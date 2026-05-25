int _profileInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

/// Modelo de dominio que representa el perfil del usuario (artista/comprador/gestor).
class ProfileModel {
  final String id;
  final String userId;
  final String nombreArtistico;
  final String disciplina;
  final String? biografia;
  final String? fotoUrl;
  final int seguidores;
  final int siguiendo;
  final bool esSeguido;
  final bool esVerificado;
  final Map<String, String> redesSociales;
  final int totalObras;
  final int obrasDisponibles;

  const ProfileModel({
    required this.id,
    required this.userId,
    required this.nombreArtistico,
    required this.disciplina,
    this.biografia,
    this.fotoUrl,
    required this.seguidores,
    required this.siguiendo,
    required this.esSeguido,
    required this.esVerificado,
    required this.redesSociales,
    required this.totalObras,
    required this.obrasDisponibles,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final redes = <String, String>{};
    if (json['redes_sociales'] is Map) {
      redes.addAll(Map<String, String>.from(json['redes_sociales'] as Map));
    }
    final websiteUrl = json['website_url']?.toString();
    final instagramUrl = json['instagram_url']?.toString();
    final facebookUrl = json['facebook_url']?.toString();
    final tiktokUrl = json['tiktok_url']?.toString();
    if (websiteUrl != null) redes['website'] = websiteUrl;
    if (instagramUrl != null) redes['instagram'] = instagramUrl;
    if (facebookUrl != null) redes['facebook'] = facebookUrl;
    if (tiktokUrl != null) redes['tiktok'] = tiktokUrl;

    return ProfileModel(
      id: json['slug']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      nombreArtistico: json['artistic_name']?.toString() ??
          json['nombre_artistico']?.toString() ??
          json['first_name']?.toString() ??
          '',
      disciplina: json['discipline']?.toString() ??
          json['disciplina']?.toString() ??
          '',
      biografia:
          json['bio']?.toString() ?? json['biografia']?.toString(),
      fotoUrl:
          json['avatar_url']?.toString() ?? json['foto_url']?.toString(),
      seguidores: _profileInt(json['followers_count'] ?? json['seguidores']),
      siguiendo: _profileInt(json['following_count'] ?? json['siguiendo']),
      esSeguido: (json['is_following'] as bool?) ??
          (json['es_seguido'] as bool?) ??
          false,
      esVerificado: (json['is_verified'] as bool?) ??
          (json['is_public'] as bool?) ??
          (json['es_verificado'] as bool?) ??
          false,
      redesSociales: redes,
      totalObras: _profileInt(json['artworks_count'] ?? json['total_obras']),
      obrasDisponibles: _profileInt(
          json['available_artworks'] ?? json['obras_disponibles']),
    );
  }
}

class ArtisticDisciplines {
  static const List<String> all = [
    'Pintura',
    'Escultura',
    'Fotografía',
    'Artesanía',
    'Música',
    'Danza',
    'Teatro',
    'Literatura',
    'Arte digital',
    'Grabado',
    'Cerámica',
    'Textil',
    'Muralismo',
    'Otro',
  ];
}
