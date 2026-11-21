import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../../musicians/domain/musician_model.dart';
import 'music_discovery_service.dart';

class MusicDiscoveryRepository {
  MusicDiscoveryRepository({MusicDiscoveryService? service})
      : _service = service ?? MusicDiscoveryService();

  final MusicDiscoveryService _service;

  Future<List<MusicianModel>> getRecommendations(String query) async {
    try {
      final list = await _service.getRecommendations(query);
      return list
          .whereType<Map>()
          .map((e) => MusicianModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      throw ApiError.message(e, fallback: 'Error al obtener recomendaciones.');
    }
  }
}
