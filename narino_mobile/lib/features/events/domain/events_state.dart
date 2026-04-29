import 'event_model.dart';

enum EventsStatus { initial, loading, success, error }

class EventsState {
  final EventsStatus status;
  final List<EventModel> events;
  final String? errorMessage;
  final String? tipoFiltro;
  final bool mostrarPasados;

  const EventsState({
    this.status = EventsStatus.initial,
    this.events = const [],
    this.errorMessage,
    this.tipoFiltro,
    this.mostrarPasados = false,
  });

  EventsState copyWith({
    EventsStatus? status,
    List<EventModel>? events,
    String? errorMessage,
    String? tipoFiltro,
    bool? mostrarPasados,
    bool clearFiltro = false,
    bool clearError = false,
  }) =>
      EventsState(
        status: status ?? this.status,
        events: events ?? this.events,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        tipoFiltro: clearFiltro ? null : (tipoFiltro ?? this.tipoFiltro),
        mostrarPasados: mostrarPasados ?? this.mostrarPasados,
      );

  bool get isLoading => status == EventsStatus.loading;
  bool get hasError => errorMessage != null;
}
