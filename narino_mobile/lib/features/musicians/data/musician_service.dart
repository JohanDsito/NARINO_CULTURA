import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class MusicianService {
  Dio get _dio => ApiClient.instance.dio;

  Future<Map<String, dynamic>> getMusicians({
    String? search,
    String? genre,
    String? city,
    String? aggregationType,
    int page = 1,
  }) async {
    final params = <String, dynamic>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (genre != null && genre.isNotEmpty) 'genre': genre,
      if (city != null && city.isNotEmpty) 'city': city,
      if (aggregationType != null && aggregationType.isNotEmpty)
        'aggregation_type': aggregationType,
      'page': page,
    };
    final res = await _dio.get(ApiConstants.musicians, queryParameters: params);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return {'results': data is List ? data : [], 'count': 0};
  }

  Future<Map<String, dynamic>> getMusicianDetail(String slug) async {
    final path =
        ApiConstants.musicianDetail.replaceAll('{slug}', slug);
    final res = await _dio.get(path);
    return res.data as Map<String, dynamic>;
  }

  Future<bool> toggleFollow(String slug) async {
    final path = ApiConstants.musicianFollow.replaceAll('{slug}', slug);
    final res = await _dio.post(path);
    final data = res.data;
    if (data is Map) {
      return data['is_following'] as bool? ??
          data['following'] as bool? ??
          false;
    }
    return false;
  }

  Future<List<dynamic>> getMusicianWorks(String slug) async {
    final path = ApiConstants.musicianWorks.replaceAll('{slug}', slug);
    final res = await _dio.get(path);
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['results'] is List) return data['results'] as List;
    return const [];
  }

  Future<List<dynamic>> getMusicianReviews(String slug) async {
    final path = ApiConstants.musicianReviews.replaceAll('{slug}', slug);
    final res = await _dio.get(path);
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['results'] is List) return data['results'] as List;
    return const [];
  }

  Future<List<dynamic>> getGenres() async {
    final res = await _dio.get(ApiConstants.musicianGenres);
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['results'] is List) return data['results'] as List;
    return const [];
  }
}
