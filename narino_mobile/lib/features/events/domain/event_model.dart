class EventModel {
  final int id;
  final String nombre;
  final String tipo;
  final DateTime fecha;
  final String lugar;
  final String? descripcion;
  final String? flyerUrl;
  final List<String> artistasRelacionados;
  final bool esDestacado;
  final bool esPasado;

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
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final parsedFecha =
        DateTime.tryParse(json['fecha']?.toString() ?? '') ?? DateTime.now();

    final rawArtistas =
        json['artistas_relacionados'] ?? json['artistas'] ?? const <dynamic>[];
    final artistasList = (rawArtistas is List ? rawArtistas : const <dynamic>[])
        .map((e) {
          if (e is Map) {
            final nombre =
                e['nombre']?.toString() ?? e['nombre_artistico']?.toString();
            if (nombre != null && nombre.isNotEmpty) return nombre;
            final id = e['id']?.toString();
            if (id != null && id.isNotEmpty) return id;
          }
          return e.toString();
        })
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return EventModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String? ?? 'otro',
      fecha: parsedFecha,
      lugar: json['lugar'] as String,
      descripcion: json['descripcion'] as String?,
      flyerUrl: json['flyer_url'] as String?,
      artistasRelacionados: artistasList,
      esDestacado: json['es_destacado'] as bool? ?? false,
      esPasado: parsedFecha.isBefore(DateTime.now()),
    );
  }

  String get tipoLabel {
    const map = {
      'concierto': '🎵 Concierto',
      'exposicion': '🎨 Exposición',
      'taller': '🖌️ Taller',
      'feria': '🏪 Feria',
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
      'Dic'
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
    'convocatoria',
    'otro',
  ];

  static const Map<String, String> labels = {
    'concierto': '🎵 Concierto',
    'exposicion': '🎨 Exposición',
    'taller': '🖌️ Taller',
    'feria': '🏪 Feria',
    'convocatoria': '📢 Convocatoria',
    'otro': '📅 Otro',
  };
}
