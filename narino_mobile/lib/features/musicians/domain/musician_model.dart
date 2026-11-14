import 'json_parsing.dart';

export 'music_genre_model.dart';
export 'musical_work_model.dart';
export 'musician_review_model.dart';

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
      name: json['artistic_name']?.toString() ?? json['name']?.toString() ?? '',
      bio: json['bio']?.toString() ?? json['biography']?.toString(),
      city: json['city']?.toString() ?? json['ciudad']?.toString(),
      photoUrl: json['profile_image_url']?.toString().isNotEmpty == true
          ? json['profile_image_url']?.toString()
          : null,
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
          parseJsonInt(json['followers_count'] ?? json['followersCount']),
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '') ??
              double.tryParse(json['rating']?.toString() ?? '') ??
              0.0,
      reviewsCount: parseJsonInt(json['reviews_count'] ?? json['reviewsCount']),
      isVerified:
          json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
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
