import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class EventsService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<dynamic>> getEvents({
    String? tipo,
    bool mostrarPasados = true,
  }) async {
    final params = <String, dynamic>{};
    if (tipo != null) params['event_type'] = tipo.toUpperCase();
    // El backend devuelve todos los eventos publicados; el filtrado de pasados
    // se aplica en el cliente con EventModel.esPasado.
    final r = await _dio.get(ApiConstants.events, queryParameters: params);
    final raw = r.data is List ? r.data as List : (r.data['results'] as List? ?? []);
    if (mostrarPasados) return raw;
    final now = DateTime.now();
    return raw.where((e) {
      final fecha = DateTime.tryParse(
        (e as Map<String, dynamic>)['start_date']?.toString() ?? '',
      );
      return fecha != null && !fecha.isBefore(now);
    }).toList();
  }

  Future<Map<String, dynamic>> getEventDetail(String id) async {
    final r =
        await _dio.get(ApiConstants.eventDetail.replaceFirst('{id}', id));
    return r.data as Map<String, dynamic>;
  }

  Future<void> registerToEvent(String id) async {
    await _dio.post(ApiConstants.eventRegister.replaceFirst('{id}', id));
  }

  /// NOTA: el backend actualmente no expone un endpoint para cancelar la
  /// inscripción a un evento (la acción `register` solo acepta POST), así
  /// que esta llamada devolverá un error hasta que se agregue soporte allá.
  Future<void> unregisterFromEvent(String id) async {
    await _dio.delete(ApiConstants.eventRegister.replaceFirst('{id}', id));
  }

  Future<Map<String, dynamic>> publishEvent({
    required String nombre,
    required String tipo,
    required String fecha,
    required String lugar,
    String? descripcion,
    String? imageUrl,
    List<String>? artistasRelacionados,
    bool isPublished = false,
  }) async {
    // Mapear parámetros mobile → campos exactos del backend
    final startDate = DateTime.tryParse(fecha) ?? DateTime.now();
    final endDate = startDate.add(const Duration(hours: 2));

    // Backend acepta solo los tipos definidos en Event.Type
    const validTypes = {
      'CONCIERTO', 'EXPOSICION', 'TALLER', 'FERIA', 'ESPECTACULO', 'OTRO',
    };
    final eventType = tipo.toUpperCase();
    final safeType = validTypes.contains(eventType) ? eventType : 'OTRO';

    final r = await _dio.post(
      ApiConstants.events,
      data: {
        'title': nombre,
        'event_type': safeType,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'location': lugar,
        if (descripcion != null && descripcion.isNotEmpty)
          'description': descripcion,
        // El backend solo acepta una URL de imagen ya alojada (Event.image_url
        // es un URLField, no hay endpoint para subir archivos de eventos).
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        'is_published': isPublished,
      },
    );
    return r.data as Map<String, dynamic>;
  }
}
