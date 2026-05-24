import 'package:dio/dio.dart';

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
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw 'No se pudo conectar al servidor.';
      }
      final body = e.response?.data;
      if (body is Map) {
        final msg = body['detail']?.toString();
        if (msg != null && msg.isNotEmpty) throw msg;
      }
      throw 'Error al obtener recomendaciones.';
    }
  }
}
