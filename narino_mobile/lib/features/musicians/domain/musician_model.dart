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
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? json['nombre']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}

class MusicalWorkModel {
  final int id;
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
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? json['titulo']?.toString() ?? '',
      description:
          json['description']?.toString() ?? json['descripcion']?.toString(),
      audioUrl: json['audio_url']?.toString() ?? json['audioUrl']?.toString(),
      coverUrl: json['cover_url']?.toString() ??
          json['coverUrl']?.toString() ??
          json['image_url']?.toString(),
      year: (json['year'] as num?)?.toInt() ?? (json['anio'] as num?)?.toInt(),
      genre: json['genre']?.toString() ?? json['genero']?.toString(),
      createdAt: DateTime.tryParse(
              json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      workType: json['work_type']?.toString(),
      youtubeUrl: json['youtube_url']?.toString(),
      soundcloudEmbed: json['soundcloud_embed']?.toString(),
      spotifyTrackUrl: json['spotify_track_url']?.toString(),
      releaseDate: json['release_date']?.toString(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
    );
  }
}

class MusicianReviewModel {
  final int id;
  final String reviewerName;
  final String? reviewerAvatar;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const MusicianReviewModel({
    required this.id,
    required this.reviewerName,
    this.reviewerAvatar,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory MusicianReviewModel.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'];
    String name = '';
    String? avatar;
    if (reviewer is Map) {
      name = reviewer['name']?.toString() ??
          reviewer['username']?.toString() ??
          reviewer['email']?.toString() ??
          '';
      avatar = reviewer['avatar_url']?.toString() ??
          reviewer['photo_url']?.toString();
    } else {
      name = json['reviewer_name']?.toString() ?? '';
      avatar = json['reviewer_avatar']?.toString();
    }

    return MusicianReviewModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      reviewerName: name,
      reviewerAvatar: avatar,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? json['comentario']?.toString(),
      createdAt: DateTime.tryParse(
              json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class MusicianModel {
  final String slug;
  final String name;
  final String? bio;
  final String? city;
  final String? photoUrl;
  final String? coverUrl;
  final List<String> genres;
  final String? aggregationType;
  final bool isFollowing;
  final int followersCount;
  final double averageRating;
  final int reviewsCount;
  final bool isVerified;

  const MusicianModel({
    required this.slug,
    required this.name,
    this.bio,
    this.city,
    this.photoUrl,
    this.coverUrl,
    required this.genres,
    this.aggregationType,
    required this.isFollowing,
    required this.followersCount,
    required this.averageRating,
    required this.reviewsCount,
    required this.isVerified,
  });

  factory MusicianModel.fromJson(Map<String, dynamic> json) {
    final rawGenres = json['genres'] ?? json['generos'] ?? const [];
    final genres = <String>[];
    if (rawGenres is List) {
      for (final g in rawGenres) {
        if (g is Map) {
          final n = g['name']?.toString() ?? g['nombre']?.toString() ?? '';
          if (n.isNotEmpty) genres.add(n);
        } else if (g is String && g.isNotEmpty) {
          genres.add(g);
        }
      }
    }

    return MusicianModel(
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['nombre']?.toString() ??
          json['user']?.toString() ??
          '',
      bio: json['bio']?.toString() ?? json['biography']?.toString(),
      city: json['city']?.toString() ?? json['ciudad']?.toString(),
      photoUrl: json['photo_url']?.toString() ??
          json['photoUrl']?.toString() ??
          json['avatar_url']?.toString(),
      coverUrl: json['cover_url']?.toString() ??
          json['coverUrl']?.toString() ??
          json['banner_url']?.toString(),
      genres: genres,
      aggregationType: json['aggregation_type']?.toString() ??
          json['tipo_agrupacion']?.toString(),
      isFollowing: json['is_following'] as bool? ??
          json['isFollowing'] as bool? ??
          false,
      followersCount:
          (json['followers_count'] as num?)?.toInt() ??
          (json['followersCount'] as num?)?.toInt() ??
          0,
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '') ??
          (json['rating'] as num?)?.toDouble() ??
          0.0,
      reviewsCount:
          (json['reviews_count'] as num?)?.toInt() ??
          (json['reviewsCount'] as num?)?.toInt() ??
          0,
      isVerified: json['is_verified'] as bool? ??
          json['isVerified'] as bool? ??
          false,
    );
  }

  MusicianModel copyWith({bool? isFollowing, int? followersCount}) =>
      MusicianModel(
        slug: slug,
        name: name,
        bio: bio,
        city: city,
        photoUrl: photoUrl,
        coverUrl: coverUrl,
        genres: genres,
        aggregationType: aggregationType,
        isFollowing: isFollowing ?? this.isFollowing,
        followersCount: followersCount ?? this.followersCount,
        averageRating: averageRating,
        reviewsCount: reviewsCount,
        isVerified: isVerified,
      );
}
