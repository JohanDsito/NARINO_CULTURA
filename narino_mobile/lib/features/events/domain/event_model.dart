/// Modelo de dominio que representa un evento cultural en la agenda.
class EventModel {
  final String id;
  final String nombre;
  final String tipo;
  final DateTime fecha;
  final String lugar;
  final String? descripcion;
  final String? flyerUrl;
  final List<String> artistasRelacionados;
  final bool esDestacado;
  final bool esPasado;
  final bool estaSuscrito;
  final double? latitud;
  final double? longitud;

  const EventModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.fecha,
    required this.lugar,
    this.descripcion,
    this.flyerUrl,
    required this.artistasRelacionados,
    required this.esDestacado,
    required this.esPasado,
    required this.estaSuscrito,
    this.latitud,
    this.longitud,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // El backend devuelve nombres en inglés; se aceptan ambos como fallback.
    final rawFecha = json['start_date'] ?? json['fecha'];
    final parsedFecha =
        DateTime.tryParse(rawFecha?.toString() ?? '') ?? DateTime.now();

    final rawTipo = (json['event_type'] ?? json['tipo'] ?? 'otro')
        .toString()
        .toLowerCase();

    final rawArtistas = json['featured_musicians'] ??
        json['artists'] ??
        json['artistas_relacionados'] ??
        json['artistas'] ??
        const <dynamic>[];
    final artistasList = (rawArtistas is List ? rawArtistas : const <dynamic>[])
        .map((e) {
          if (e is Map) {
            final nombre =
                e['nombre']?.toString() ?? e['nombre_artistico']?.toString() ??
                e['artistic_name']?.toString() ?? e['name']?.toString();
            if (nombre != null && nombre.isNotEmpty) return nombre;
            final id = e['id']?.toString();
            if (id != null && id.isNotEmpty) return id;
          }
          return e.toString();
        })
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return EventModel(
      id: json['id']?.toString() ?? '',
      nombre: json['title']?.toString() ??
          json['nombre']?.toString() ??
          'Sin título',
      tipo: rawTipo,
      fecha: parsedFecha,
      lugar: json['location']?.toString() ??
          json['lugar']?.toString() ??
          'Sin lugar',
      descripcion: json['description']?.toString() ??
          json['descripcion']?.toString(),
      flyerUrl: json['flyer_url']?.toString() ??
          json['image_url']?.toString() ??
          json['flyer']?.toString(),
      artistasRelacionados: artistasList,
      esDestacado: json['es_destacado'] as bool? ??
          json['is_featured'] as bool? ??
          false,
      esPasado: parsedFecha.isBefore(DateTime.now()),
      estaSuscrito: json['esta_suscrito'] as bool? ??
          json['is_subscribed'] as bool? ??
          false,
      latitud: (json['latitud'] as num?)?.toDouble() ??
          (json['latitude'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble() ??
          (json['longitude'] as num?)?.toDouble(),
    );
  }

  String get tipoLabel {
    const map = {
      'concierto': '🎵 Concierto',
      'exposicion': '🎨 Exposición',
      'taller': '🖌️ Taller',
      'feria': '🏪 Feria',
      'espectaculo': '🎭 Espectáculo',
      'convocatoria': '📢 Convocatoria',
      'otro': '📅 Evento',
    };
    return map[tipo] ?? '📅 Evento';
  }

  String get fechaFormateada {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} · ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}

class EventTypes {
  static const List<String> all = [
    'concierto',
    'exposicion',
    'taller',
    'feria',
    'espectaculo',
    'convocatoria',
    'otro',
  ];

  static const Map<String, String> labels = {
    'concierto': '🎵 Concierto',
    'exposicion': '🎨 Exposición',
    'taller': '🖌️ Taller',
    'feria': '🏪 Feria',
    'espectaculo': '🎭 Espectáculo',
    'convocatoria': '📢 Convocatoria',
    'otro': '📅 Otro',
  };
}
