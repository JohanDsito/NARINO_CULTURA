class TopArtwork {
  const TopArtwork({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.visits,
  });

  final int? id;
  final String? title;
  final String? imageUrl;
  final int visits;

  factory TopArtwork.fromJson(Map<String, dynamic> json) {
    int? parseId(Object? v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '');
    }

    int parseVisits(Object? v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return TopArtwork(
      id: parseId(json['id'] ?? json['obra_id'] ?? json['artwork_id']),
      title: (json['titulo'] ?? json['title'] ?? '').toString().trim().isEmpty
          ? null
          : (json['titulo'] ?? json['title']).toString(),
      imageUrl:
          (json['imagen_url'] ??
                  json['image_url'] ??
                  json['imagen'] ??
                  json['image'])
              ?.toString(),
      visits: parseVisits(json['visitas'] ?? json['views']),
    );
  }
}
