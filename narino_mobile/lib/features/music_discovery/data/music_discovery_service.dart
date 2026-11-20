import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class MusicDiscoveryService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<dynamic>> getRecommendations(String query) async {
    final res = await _dio.post(
      ApiConstants.musicDiscoveryRecommendations,
      data: {'query': query},
    );
    final data = res.data;
    if (data is List) return data;
    if (data is Map) {
      final results = data['results'] ?? data['recommendations'] ?? data['data'];
      if (results is List) return results;
    }
    return const [];
  }
}
