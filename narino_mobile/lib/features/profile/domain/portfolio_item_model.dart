class PortfolioItemModel {
  final int id;
  final String tipo;
  final String url;
  final String? titulo;
  final String? descripcion;
  final int orden;

  const PortfolioItemModel({
    required this.id,
    required this.tipo,
    required this.url,
    this.titulo,
    this.descripcion,
    required this.orden,
  });

  factory PortfolioItemModel.fromJson(Map<String, dynamic> json) =>
      PortfolioItemModel(
        id: json['id'] as int? ?? 0,
        tipo: json['tipo']?.toString() ?? 'imagen',
        url: json['url']?.toString() ?? '',
        titulo: json['titulo']?.toString(),
        descripcion: json['descripcion']?.toString(),
        orden: json['orden'] as int? ?? 0,
      );

  bool get isImage => tipo == 'imagen';
  bool get isVideo => tipo == 'video';
}
