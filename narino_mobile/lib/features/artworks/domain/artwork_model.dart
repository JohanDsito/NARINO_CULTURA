class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;
  final String slug;

  /// Nombre para mostrar: el backend guarda algunas categorías sin tilde.
  String get displayName => _conTildes[name.toLowerCase()] ?? name;

  static const _conTildes = {
    'fotografia': 'Fotografía',
    'artesania': 'Artesanía',
    'ceramica': 'Cerámica',
  };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

/// Modelo de dominio que representa una obra de arte dentro del catálogo/marketplace.
class ArtworkModel {
  final String id;
  final String titulo;
  final String descripcion;
  /// Nombre de la categoría para mostrar (de `category_detail.name`).
  final String categoria;

  /// Id de la categoría en el backend (`category`), para editar/filtrar.
  final int? categoriaId;
  final String? tecnica;
  final String? dimensiones;
  final int? anio;
  final double? precio;
  final String estado;
  final List<String> imagenes;
  final String artistaId;
  final String artistaSlug;
  final String artistaNombre;
  final String? artistaFoto;
  final int viewsCount;
  final bool esFavorito;
  final DateTime creadoEn;

  const ArtworkModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    this.categoriaId,
    this.tecnica,
    this.dimensiones,
    this.anio,
    this.precio,
    required this.estado,
    required this.imagenes,
    required this.artistaId,
    this.artistaSlug = '',
    required this.artistaNombre,
    this.artistaFoto,
    required this.viewsCount,
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
    final precioNum =
        priceRaw != null ? double.tryParse(priceRaw.toString()) : null;
    // El backend usa price = 0 para obras solo de exhibición.
    final precio = (precioNum == null || precioNum <= 0) ? null : precioNum;

    // ── status (normalise English → Spanish internal values) ─────────────────
    // Solo subasta y vendida son estados explícitos; cualquier otro valor
    // (available, for_sale, active, published, vacío, desconocido) → disponible.
    final rawStatus =
        (json['status'] as String? ?? json['estado'] as String? ?? '').toLowerCase();
    final String estado;
    switch (rawStatus) {
      case 'in_auction':
      case 'en_subasta':
        estado = 'en_subasta';
      case 'sold':
      case 'vendida':
      case 'vendido':
        estado = 'vendida';
      default:
        estado = 'disponible';
    }

    // ── category ─────────────────────────────────────────────────────────────
    // `category` es el id; el nombre viene en `category_detail`.
    final categoriaRaw = json['category'];
    final detalle = json['category_detail'];
    final categoriaId = categoriaRaw is int
        ? categoriaRaw
        : int.tryParse(categoriaRaw?.toString() ?? '');
    final nombreDetalle =
        detalle is Map ? detalle['name']?.toString() ?? '' : '';
    String categoria = json['categoria'] as String? ?? nombreDetalle;
    if (categoria.isEmpty && categoriaRaw is String && categoriaId == null) {
      categoria = categoriaRaw; // datos locales/antiguos con el nombre
    }
    categoria = CategoryModel(id: 0, name: categoria, slug: '').displayName;

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
      categoriaId: categoriaId,
      tecnica: (tecnicaRaw?.isEmpty ?? true) ? null : tecnicaRaw,
      dimensiones: (dimensionesRaw?.isEmpty ?? true) ? null : dimensionesRaw,
      anio: json['anio'] as int?,
      precio: precio,
      estado: estado,
      imagenes: imagenes,
      artistaId: json['artist']?.toString() ??
          json['artista_id']?.toString() ??
          '',
      artistaSlug: json['artist_slug'] as String? ?? '',
      artistaNombre: artistaNombre,
      artistaFoto: json['artista_foto'] as String?,
      viewsCount: json['views_count'] as int? ?? 0,
      esFavorito: json['es_favorito'] as bool? ?? false,
      creadoEn: DateTime.tryParse(
              json['created_at'] as String? ??
                  json['creado_en'] as String? ??
                  '') ??
          DateTime.now(),
    );
  }

  ArtworkModel copyWith({bool? esFavorito}) => ArtworkModel(
        id: id,
        titulo: titulo,
        descripcion: descripcion,
        categoria: categoria,
        categoriaId: categoriaId,
        tecnica: tecnica,
        dimensiones: dimensiones,
        anio: anio,
        precio: precio,
        estado: estado,
        imagenes: imagenes,
        artistaId: artistaId,
        artistaSlug: artistaSlug,
        artistaNombre: artistaNombre,
        artistaFoto: artistaFoto,
        viewsCount: viewsCount,
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
