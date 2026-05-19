import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class EventsService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<dynamic>> getEvents({
    String? tipo,
    bool mostrarPasados = false,
  }) async {
    final params = <String, dynamic>{};
    if (tipo != null) params['tipo'] = tipo;
    if (mostrarPasados) params['incluir_pasados'] = true;
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
    final formData = FormData.fromMap({
      'nombre': nombre,
      'tipo': tipo,
      'fecha': fecha,
      'lugar': lugar,
      if (descripcion != null) 'descripcion': descripcion,
      if (artistasRelacionados != null)
        'artistas_relacionados': artistasRelacionados,
      if (flyer != null)
        'flyer': await MultipartFile.fromFile(
          flyer.path,
          filename: flyer.path.split('/').last,
        ),
    });
    final r = await _dio.post(
      ApiConstants.events,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return r.data as Map<String, dynamic>;
  }
}
