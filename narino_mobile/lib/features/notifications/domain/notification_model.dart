/// Modelo de dominio de una notificación de la bandeja (HU-B09).
///
/// Contrato del backend (`NotificationSerializer`):
/// `{id: uuid, type, title, body, data: {...}, read, read_at, created_at}`.
/// `data` trae los ids del recurso relacionado (`auction_id`, `event_id`,
/// `order_id`, ...) y una `url` pensada para la web.
class NotificationModel {
  final String id;
  final String tipo;
  final String titulo;
  final String descripcion;
  final DateTime creadoEn;
  final bool leida;
  final Map<String, dynamic> data;

  const NotificationModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.creadoEn,
    required this.leida,
    this.data = const {},
  });

  /// Id del recurso relacionado (subasta, evento, orden u obra), si existe.
  String? get referenciaId {
    for (final key in const [
      'auction_id',
      'event_id',
      'artwork_id',
      'order_id',
    ]) {
      final v = _nonEmpty(data[key]);
      if (v != null) return v;
    }
    return null;
  }

  /// Ruta de la app móvil a la que lleva la notificación, o `null`.
  String? get ruta {
    final auction = _nonEmpty(data['auction_id']);
    if (auction != null) return '/auctions/$auction';
    final event = _nonEmpty(data['event_id']);
    if (event != null) return '/events/$event';
    final artwork = _nonEmpty(data['artwork_id']);
    if (artwork != null) return '/artworks/$artwork';
    final order = _nonEmpty(data['order_id']);
    if (order != null) return '/marketplace/order/$order';
    return null;
  }

  NotificationModel copyWith({bool? leida}) => NotificationModel(
        id: id,
        tipo: tipo,
        titulo: titulo,
        descripcion: descripcion,
        creadoEn: creadoEn,
        leida: leida ?? this.leida,
        data: data,
      );

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'] ?? json['creado_en'];
    final rawData = json['data'] ?? json['payload'];
    final readAt = json['read_at'];

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      tipo: (json['type'] ?? json['tipo'] ?? '').toString(),
      titulo: (json['title'] ?? json['titulo'] ?? 'Notificación').toString(),
      descripcion: (json['body'] ?? json['descripcion'] ?? json['message'] ?? '')
          .toString(),
      creadoEn: DateTime.tryParse(created?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      leida: json['read'] == true ||
          json['leida'] == true ||
          (readAt != null && readAt.toString().isNotEmpty),
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : const {},
    );
  }

  static String? _nonEmpty(Object? v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty || s == 'null') ? null : s;
  }
}
