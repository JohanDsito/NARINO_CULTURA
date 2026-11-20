int? _parseIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

class MusicalWorkModel {
  /// UUID del backend.
  final String id;
  final String title;
  final String? description;
  final String? audioUrl;
  final String? coverUrl;
  final int? year;
  final String? genre;
  final DateTime createdAt;
  final String? workType;
  final String? youtubeUrl;
  final String? soundcloudEmbed;
  final String? spotifyTrackUrl;
  final String? releaseDate;
  final int? durationSeconds;

  const MusicalWorkModel({
    required this.id,
    required this.title,
    this.description,
    this.audioUrl,
    this.coverUrl,
    this.year,
    this.genre,
    required this.createdAt,
    this.workType,
    this.youtubeUrl,
    this.soundcloudEmbed,
    this.spotifyTrackUrl,
    this.releaseDate,
    this.durationSeconds,
  });

  factory MusicalWorkModel.fromJson(Map<String, dynamic> json) {
    return MusicalWorkModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['titulo']?.toString() ?? '',
      description:
          json['description']?.toString() ?? json['descripcion']?.toString(),
      audioUrl: json['audio_file']?.toString() ?? json['audio_url']?.toString(),
      coverUrl: json['thumbnail']?.toString() ?? json['cover_url']?.toString(),
      year: _parseIntOrNull(json['year']) ?? _parseIntOrNull(json['anio']),
      genre: json['genre']?.toString() ?? json['genero']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      workType: json['work_type']?.toString(),
      youtubeUrl: json['youtube_url']?.toString(),
      soundcloudEmbed: json['soundcloud_embed']?.toString(),
      spotifyTrackUrl: json['spotify_track_url']?.toString(),
      releaseDate: json['release_date']?.toString(),
      durationSeconds: _parseIntOrNull(json['duration_seconds']),
    );
  }
}
