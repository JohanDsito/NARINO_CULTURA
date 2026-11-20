import 'json_parsing.dart';

class MusicianReviewModel {
  /// UUID del backend.
  final String id;
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
      id: json['id']?.toString() ?? '',
      reviewerName: name,
      reviewerAvatar: avatar,
      rating: parseJsonInt(json['rating']),
      comment: json['comment']?.toString() ?? json['comentario']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
