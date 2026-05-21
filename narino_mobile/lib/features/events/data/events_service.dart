import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class EventsService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<dynamic>> getEvents({
    String? tipo,
    bool mostrarPasados = false,
  }) async {
    final params = <String, dynamic>{};
    if (tipo != null) params['event_type'] = tipo.toUpperCase();
    final r = await _dio.get(ApiConstants.events, queryParameters: params);
    return r.data is List ? r.data as List : (r.data['results'] as List? ?? []);
  }

  Future<Map<String, dynamic>> getEventDetail(String id) async {
    final r =
        await _dio.get(ApiConstants.eventDetail.replaceFirst('{id}', id));
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> publishEvent({
    required String nombre,
    required String tipo,
    required String fecha,
    required String lugar,
    String? descripcion,
    File? flyer,
    List<String>? artistasRelacionados,
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
        'is_published': false,
      },
    );
    return r.data as Map<String, dynamic>;
  }
}
