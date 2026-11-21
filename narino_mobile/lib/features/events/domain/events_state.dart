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
    this.mostrarPasados = true,
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

  /// Búsqueda local por nombre, lugar o descripción (el backend no tiene
  /// "artistas relacionados", así que el filtro anterior nunca encontraba nada).
  List<EventModel> get filteredEvents {
    final q = _norm(filtroArtista ?? '');
    if (q.isEmpty) return events;
    return events.where((e) {
      final texto = _norm('${e.nombre} ${e.lugar} ${e.descripcion ?? ''} '
          '${e.artistasRelacionados.join(' ')}');
      return texto.contains(q);
    }).toList();
  }

  static String _norm(String s) {
    const a = 'áéíóúüñ', b = 'aeiouun';
    final out = StringBuffer();
    for (final c in s.toLowerCase().trim().split('')) {
      final i = a.indexOf(c);
      out.write(i < 0 ? c : b[i]);
    }
    return out.toString();
  }
}
