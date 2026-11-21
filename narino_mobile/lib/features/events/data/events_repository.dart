import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
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
    Duration duracion = const Duration(hours: 2),
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
        duracion: duracion,
      ));
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  String _parseError(DioException e) => ApiError.message(e, byStatus: const {
        401: 'Inicia sesión para continuar.',
        403: 'Solo artistas y gestores culturales pueden publicar eventos.',
      });
}
