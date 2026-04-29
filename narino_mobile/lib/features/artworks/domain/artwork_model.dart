class ArtworkModel {
  final int id;
  final String titulo;
  final String descripcion;
  final String categoria;
  final String? tecnica;
  final String? dimensiones;
  final int? anio;
  final double? precio;
  final String estado;
  final List<String> imagenes;
  final int artistaId;
  final String artistaNombre;
  final String? artistaFoto;
  final int cantidadFavoritos;
  final bool esFavorito;
  final DateTime creadoEn;

  const ArtworkModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    this.tecnica,
    this.dimensiones,
    this.anio,
    this.precio,
    required this.estado,
    required this.imagenes,
    required this.artistaId,
    required this.artistaNombre,
    this.artistaFoto,
    required this.cantidadFavoritos,
    required this.esFavorito,
    required this.creadoEn,
  });

  factory ArtworkModel.fromJson(Map<String, dynamic> json) => ArtworkModel(
        id: json['id'] as int,
        titulo: json['titulo'] as String,
        descripcion: json['descripcion'] as String? ?? '',
        categoria: json['categoria'] as String,
        tecnica: json['tecnica'] as String?,
        dimensiones: json['dimensiones'] as String?,
        anio: json['anio'] as int?,
        precio: json['precio'] != null
            ? double.tryParse(json['precio'].toString())
            : null,
        estado: json['estado'] as String? ?? 'disponible',
        imagenes: (json['imagenes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        artistaId: json['artista_id'] as int,
        artistaNombre: json['artista_nombre'] as String? ?? '',
        artistaFoto: json['artista_foto'] as String?,
        cantidadFavoritos: json['cantidad_favoritos'] as int? ?? 0,
        esFavorito: json['es_favorito'] as bool? ?? false,
        creadoEn: DateTime.tryParse(json['creado_en'] as String? ?? '') ??
            DateTime.now(),
      );

  ArtworkModel copyWith({bool? esFavorito, int? cantidadFavoritos}) =>
      ArtworkModel(
        id: id,
        titulo: titulo,
        descripcion: descripcion,
        categoria: categoria,
        tecnica: tecnica,
        dimensiones: dimensiones,
        anio: anio,
        precio: precio,
        estado: estado,
        imagenes: imagenes,
        artistaId: artistaId,
        artistaNombre: artistaNombre,
        artistaFoto: artistaFoto,
        cantidadFavoritos: cantidadFavoritos ?? this.cantidadFavoritos,
        esFavorito: esFavorito ?? this.esFavorito,
        creadoEn: creadoEn,
      );

  bool get isDisponible => estado == 'disponible';
}

const kCategoriasNarino = [
  'Pintura',
  'Escultura',
  'Artesanía',
  'Fotografía',
  'Grabado',
  'Dibujo',
  'Textiles',
  'Cerámica',
  'Joyería',
  'Arte Digital',
  'Música',
  'Danza',
  'Teatro',
  'Literatura',
  'Otro',
];

const kTecnicasNarino = [
  'Barniz de Pasto',
  'Tamo',
  'Talla en madera',
  'Acuarela',
  'Óleo',
  'Acrílico',
  'Lápiz',
  'Carboncillo',
  'Serigrafía',
  'Tejido',
  'Cerámica a mano',
  'Fundición',
  'Fotografía análoga',
  'Fotografía digital',
  'Otra',
];
