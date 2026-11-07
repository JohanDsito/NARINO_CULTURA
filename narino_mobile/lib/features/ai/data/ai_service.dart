import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../artworks/domain/artwork_model.dart';
import '../../events/domain/event_model.dart';

class AiService {
  Dio get _dio => ApiClient.instance.dio;

  /// Sugiere una categoría para una obra a partir de su título (usada al
  /// componer una obra nueva, antes de que exista un ID en el backend).
  Future<String> suggestCategory(String titulo) async {
    final response = await _dio.post(
      '/ai/suggest-category/',
      data: {'titulo': titulo},
    );
    final data = response.data;
    final categoria = (data is Map ? data['categoria'] : null)?.toString();
    if (categoria == null || categoria.isEmpty) {
      throw const FormatException('Respuesta vacía del servidor.');
    }
    return categoria;
  }

  /// Genera una descripción para una obra a partir de su título y categoría.
  Future<String> generateDescription({
    required String titulo,
    required int categoriaId,
  }) async {
    final response = await _dio.post(
      '/ai/generate-description/',
      data: {'titulo': titulo, 'categoria': categoriaId},
    );
    final data = response.data;
    final descripcion = (data is Map ? data['descripcion'] : null)?.toString();
    if (descripcion == null || descripcion.isEmpty) {
      throw const FormatException('Respuesta vacía del servidor.');
    }
    return descripcion;
  }

  /// Sends a message to the cultural AI assistant.
  /// [history] is a list of previous turns: `[{'role': 'user'/'assistant', 'text': '...'}]`
  Future<String> chat({
    required String mensaje,
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final res = await _dio.post(ApiConstants.aiChat, data: {
        'message': mensaje,
        'history': history,
      });
      final data = res.data;
      if (data is Map) {
        final r = data['reply']?.toString();
        if (r != null && r.isNotEmpty) return r;
      }
      throw const FormatException('Respuesta inválida del servidor.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const FormatException(
            'El asistente IA no está disponible en este momento.');
      }
      rethrow;
    }
  }

  /// Returns artworks sorted by views (most-viewed first) as recommendations.
  /// Uses the real artworks catalog — the AI recommendations endpoint does not exist.
  Future<List<ArtworkModel>> getArtworkRecommendations() async {
    try {
      final res = await _dio.get(
        ApiConstants.artworks,
        queryParameters: {'page_size': 10, 'ordering': '-views_count'},
      );
      final data = res.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => ArtworkModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List)
            .whereType<Map>()
            .map((e) => ArtworkModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const <ArtworkModel>[];
    } catch (_) {
      return const <ArtworkModel>[];
    }
  }

  /// Returns upcoming events as recommendations.
  /// Uses the real events catalog — the AI event-recommendations endpoint does not exist.
  Future<List<EventModel>> getEventRecommendations() async {
    try {
      final res = await _dio.get(ApiConstants.events);
      final data = res.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List)
            .whereType<Map>()
            .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const <EventModel>[];
    } catch (_) {
      return const <EventModel>[];
    }
  }
}
