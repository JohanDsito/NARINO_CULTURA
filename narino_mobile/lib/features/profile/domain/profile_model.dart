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

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id']?.toString() ?? '',
    userId: json['user_id']?.toString() ?? '',
    nombreArtistico: json['nombre_artistico']?.toString() ?? '',
    disciplina: json['disciplina']?.toString() ?? '',
    biografia: json['biografia']?.toString(),
    fotoUrl: json['foto_url']?.toString(),
    seguidores: json['seguidores'] as int? ?? 0,
    siguiendo: json['siguiendo'] as int? ?? 0,
    esSeguido: json['es_seguido'] as bool? ?? false,
    esVerificado: json['es_verificado'] as bool? ?? false,
    redesSociales: Map<String, String>.from(
      json['redes_sociales'] as Map? ?? {},
    ),
    totalObras: json['total_obras'] as int? ?? 0,
    obrasDisponibles: json['obras_disponibles'] as int? ?? 0,
  );
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
