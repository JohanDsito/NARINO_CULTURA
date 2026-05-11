import 'event_model.dart';

enum EventsStatus { initial, loading, success, error }

class EventsState {
  final EventsStatus status;
  final List<EventModel> events;
  final String? errorMessage;
  final String? tipoFiltro;
  final String? filtroArtista;
  final bool mostrarPasados;

  const EventsState({
    this.status = EventsStatus.initial,
    this.events = const [],
    this.errorMessage,
    this.tipoFiltro,
    this.filtroArtista,
    this.mostrarPasados = false,
  });

  EventsState copyWith({
    EventsStatus? status,
    List<EventModel>? events,
    String? errorMessage,
    String? tipoFiltro,
    String? filtroArtista,
    bool? mostrarPasados,
    bool clearFiltro = false,
    bool clearArtista = false,
    bool clearError = false,
  }) =>
      EventsState(
        status: status ?? this.status,
        events: events ?? this.events,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        tipoFiltro: clearFiltro ? null : (tipoFiltro ?? this.tipoFiltro),
        filtroArtista:
            clearArtista ? null : (filtroArtista ?? this.filtroArtista),
        mostrarPasados: mostrarPasados ?? this.mostrarPasados,
      );

  bool get isLoading => status == EventsStatus.loading;
  bool get hasError => errorMessage != null;

  List<EventModel> get filteredEvents {
    if (filtroArtista == null || filtroArtista!.isEmpty) return events;
    final query = filtroArtista!.toLowerCase();
    return events.where((e) {
      return e.artistasRelacionados.any((a) => a.toLowerCase().contains(query));
    }).toList();
  }
}
