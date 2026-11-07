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
      ApiConstants.aiSuggestCategory,
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
      ApiConstants.aiGenerateDescription,
      data: {'titulo': titulo, 'categoria': categoriaId},
    );
    final data = response.data;
    final descripcion = (data is Map ? data['descripcion'] : null)?.toString();
    if (descripcion == null || descripcion.isEmpty) {
      throw const FormatException('Respuesta vacía del servidor.');
    }
    return descripcion;
  }

  /// Envía un mensaje al asistente cultural (`POST /api/v1/chat/`).
  ///
  /// [history] son los turnos anteriores `{'role': 'user'|'model', 'text'}`.
  /// Gemini solo acepta `user` y `model`: con `assistant` el historial
  /// fallaba y el backend respondía con sus reglas de respaldo.
  Future<String> chat({
    required String mensaje,
    List<Map<String, String>> history = const [],
  }) async {
    String? reply(Object? data) {
      if (data is! Map) return null;
      final r = data['reply']?.toString().trim();
      return (r == null || r.isEmpty) ? null : r;
    }

    try {
      final res = await _dio.post(ApiConstants.aiChat, data: {
        'message': mensaje,
        'history': [
          for (final h in history)
            {
              'role': h['role'] == 'user' ? 'user' : 'model',
              'text': h['text'] ?? '',
            },
        ],
      });
      final r = reply(res.data);
      if (r != null) return r;
      throw const FormatException('Respuesta inválida del servidor.');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // 503: la IA no está disponible, pero el backend manda una respuesta
      // de respaldo en `reply`; se muestra en vez de un error.
      final respaldo = reply(e.response?.data);
      if (code == 503 && respaldo != null) return respaldo;
      if (code == 429) {
        throw const FormatException(
            'Vas muy rápido. Espera un momento y vuelve a preguntar.');
      }
      if (code == 404 || code == 503) {
        throw const FormatException(
            'El asistente no está disponible en este momento.');
      }
      throw const FormatException(
          'No pudimos conectar con el asistente. Revisa tu conexión.');
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
