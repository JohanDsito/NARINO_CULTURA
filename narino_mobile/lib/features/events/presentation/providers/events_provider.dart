import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../data/events_repository.dart';
import '../../domain/event_model.dart';
import '../../domain/events_state.dart';

final eventsRepositoryProvider =
    Provider<EventsRepository>((ref) => EventsRepository());

final eventsProvider =
    StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  return EventsNotifier(ref.read(eventsRepositoryProvider));
});

final eventDetailProvider =
    FutureProvider.family<EventModel, String>((ref, id) async {
  return ref.read(eventsRepositoryProvider).getEventDetail(id);
});

class EventsNotifier extends StateNotifier<EventsState> {
  final EventsRepository _repo;
  EventsNotifier(this._repo) : super(const EventsState());

  Future<void> loadEvents() async {
    state = state.copyWith(status: EventsStatus.loading, clearError: true);
    try {
      final events = await _repo.getEvents(
        tipo: state.tipoFiltro,
        mostrarPasados: state.mostrarPasados,
      );
      state = state.copyWith(status: EventsStatus.success, events: events);
    } catch (e) {
      state = state.copyWith(
          status: EventsStatus.error, errorMessage: e.toString());
    }
  }

  void setTipoFiltro(String? tipo) {
    state = state.copyWith(tipoFiltro: tipo, clearFiltro: tipo == null);
    loadEvents();
  }

  void setFiltroArtista(String? artista) {
    state = state.copyWith(
        filtroArtista: artista,
        clearArtista: artista == null || artista.isEmpty);
    // El filtrado por artista se hace en el frontend sobre la lista ya cargada
    // según el prompt, pero si el repo soporta filtro por artista sería mejor.
    // Sin embargo, las instrucciones dicen "filtra eventos que tengan ese texto en su lista de artistasRelacionados"
    // lo cual implica un filtrado local si ya tenemos todos los eventos.
  }

  void setMostrarPasados(bool value) {
    if (state.mostrarPasados == value) return;
    state = state.copyWith(mostrarPasados: value);
    loadEvents();
  }

  void togglePasados() {
    state = state.copyWith(mostrarPasados: !state.mostrarPasados);
    loadEvents();
  }

  Future<bool> publishEvent({
    required String nombre,
    required String tipo,
    required String fecha,
    required String lugar,
    String? descripcion,
    File? flyer,
    List<String>? artistas,
  }) async {
    try {
      final nuevo = await _repo.publishEvent(
        nombre: nombre,
        tipo: tipo,
        fecha: fecha,
        lugar: lugar,
        descripcion: descripcion,
        flyer: flyer,
        artistasRelacionados: artistas,
      );
      state = state.copyWith(events: [nuevo, ...state.events]);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}
