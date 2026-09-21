import 'package:dio/dio.dart';

import '../domain/event_model.dart';
import 'events_service.dart';

/// Repositorio de eventos: administra lectura de agenda y publicación de eventos.
class EventsRepository {
  final EventsService _service;
  EventsRepository({EventsService? service})
      : _service = service ?? EventsService();

  Future<List<EventModel>> getEvents(
      {String? tipo, bool mostrarPasados = false}) async {
    try {
      final data =
          await _service.getEvents(tipo: tipo, mostrarPasados: mostrarPasados);
      return data
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<EventModel> getEventDetail(String id) async {
    try {
      return EventModel.fromJson(await _service.getEventDetail(id));
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> registerToEvent(String id) async {
    try {
      await _service.registerToEvent(id);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> unregisterFromEvent(String id) async {
    try {
      await _service.unregisterFromEvent(id);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<EventModel> publishEvent({
    required String nombre,
    required String tipo,
    required String fecha,
    required String lugar,
    String? descripcion,
    String? imageUrl,
    List<String>? artistasRelacionados,
    bool isPublished = false,
  }) async {
    try {
      return EventModel.fromJson(await _service.publishEvent(
        nombre: nombre,
        tipo: tipo,
        fecha: fecha,
        lugar: lugar,
        descripcion: descripcion,
        imageUrl: imageUrl,
        artistasRelacionados: artistasRelacionados,
        isPublished: isPublished,
      ));
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  String _parseError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Sin conexión al servidor.';
    }
    if (e.response?.statusCode == 403) {
      return 'Solo gestores culturales pueden publicar eventos.';
    }
    if (e.response?.statusCode == 400) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('detail')) {
        return data['detail'].toString();
      }
    }
    return 'Ocurrió un error inesperado.';
  }
}
