/// Modelo de dominio que representa una obra de arte dentro del catálogo/marketplace.
class ArtworkModel {
  final String id;
  final String titulo;
  final String descripcion;
  final String categoria;
  final String? tecnica;
  final String? dimensiones;
  final int? anio;
  final double? precio;
  final String estado;
  final List<String> imagenes;
  final String artistaId;
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

  factory ArtworkModel.fromJson(Map<String, dynamic> json) {
    // Backend returns English field names; Spanish names kept as fallback for
    // any legacy or locally-constructed JSON.

    // ── image URLs ──────────────────────────────────────────────────────────
    // Primary: extract image_url from the nested `images` list.
    final List<String> imagenes = [];
    final rawImages = json['images'];
    if (rawImages is List) {
      for (final item in rawImages) {
        if (item is Map<String, dynamic>) {
          final url = item['image_url'] as String? ?? '';
          if (url.isNotEmpty) imagenes.add(url);
        }
      }
    }
    // Fallback: flat `imagenes` list (Spanish field name).
    if (imagenes.isEmpty) {
      final rawImagenes = json['imagenes'];
      if (rawImagenes is List) {
        imagenes.addAll(
          rawImagenes.map((e) => e.toString()).where((s) => s.isNotEmpty),
        );
      }
    }
    // Prepend main_image_url when it isn't already the first entry.
    final mainUrl = json['main_image_url'] as String? ?? '';
    if (mainUrl.isNotEmpty) {
      imagenes.remove(mainUrl);
      imagenes.insert(0, mainUrl);
    }

    // ── artist name ─────────────────────────────────────────────────────────
    // Prefer explicit name; derive from slug when absent.
    String artistaNombre = json['artista_nombre'] as String? ?? '';
    if (artistaNombre.isEmpty) {
      final slug = json['artist_slug'] as String? ?? '';
      if (slug.isNotEmpty) {
        artistaNombre = slug
            .split('-')
            .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
      }
    }

    // ── price ────────────────────────────────────────────────────────────────
    final priceRaw = json['price'] ?? json['precio'];
    final precio =
        priceRaw != null ? double.tryParse(priceRaw.toString()) : null;

    // ── status (normalise to lowercase) ──────────────────────────────────────
    final estado =
        (json['status'] as String? ?? json['estado'] as String? ?? 'disponible')
            .toLowerCase();

    // ── category ─────────────────────────────────────────────────────────────
    final categoriaRaw = json['category'];
    final categoria = json['categoria'] as String? ??
        (categoriaRaw != null ? categoriaRaw.toString() : '');

    // ── optional text fields ─────────────────────────────────────────────────
    final tecnicaRaw =
        json['technique'] as String? ?? json['tecnica'] as String?;
    final dimensionesRaw =
        json['dimensions'] as String? ?? json['dimensiones'] as String?;

    return ArtworkModel(
      id: json['id']?.toString() ?? '',
      titulo: json['title'] as String? ?? json['titulo'] as String? ?? '',
      descripcion:
          json['description'] as String? ?? json['descripcion'] as String? ?? '',
      categoria: categoria,
      tecnica: (tecnicaRaw?.isEmpty ?? true) ? null : tecnicaRaw,
      dimensiones: (dimensionesRaw?.isEmpty ?? true) ? null : dimensionesRaw,
      anio: json['anio'] as int?,
      precio: precio,
      estado: estado,
      imagenes: imagenes,
      artistaId: json['artist']?.toString() ??
          json['artista_id']?.toString() ??
          '',
      artistaNombre: artistaNombre,
      artistaFoto: json['artista_foto'] as String?,
      cantidadFavoritos:
          json['views_count'] as int? ?? json['cantidad_favoritos'] as int? ?? 0,
      esFavorito: json['es_favorito'] as bool? ?? false,
      creadoEn: DateTime.tryParse(
              json['created_at'] as String? ??
                  json['creado_en'] as String? ??
                  '') ??
          DateTime.now(),
    );
  }

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
