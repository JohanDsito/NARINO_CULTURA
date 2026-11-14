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
