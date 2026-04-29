import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../artworks/domain/artwork_model.dart';
import '../../events/domain/event_model.dart';

class AiService {
  Dio get _dio => ApiClient.instance.dio;

  Future<String> chat({required String mensaje}) async {
    final res = await _dio.post(ApiConstants.aiChat, data: {'mensaje': mensaje});
    final data = res.data;
    if (data is Map) {
      final r = data['respuesta']?.toString();
      if (r != null && r.isNotEmpty) return r;
    }
    throw const FormatException('Respuesta inválida del servidor.');
  }

  Future<List<ArtworkModel>> getArtworkRecommendations() async {
    final res = await _dio.get(ApiConstants.aiRecommendations);
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => ArtworkModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map && data['results'] is List) {
      final list = data['results'] as List;
      return list
          .whereType<Map>()
          .map((e) => ArtworkModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const <ArtworkModel>[];
  }

  Future<List<EventModel>> getEventRecommendations() async {
    final res = await _dio.get(ApiConstants.aiEventRecommendations);
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map && data['results'] is List) {
      final list = data['results'] as List;
      return list
          .whereType<Map>()
          .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const <EventModel>[];
  }

  Future<Map<String, dynamic>> getArtistStats() async {
    final res = await _dio.get(ApiConstants.aiArtistStats);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Respuesta inválida del servidor.');
  }
}

