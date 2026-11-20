import 'json_parsing.dart';

class MusicGenreModel {
  final int id;
  final String name;
  final String slug;

  const MusicGenreModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory MusicGenreModel.fromJson(Map<String, dynamic> json) {
    return MusicGenreModel(
      id: parseJsonInt(json['id']),
      name: json['name']?.toString() ?? json['nombre']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}
