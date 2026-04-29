class NotificationModel {
  final int id;
  final String tipo;
  final String titulo;
  final String descripcion;
  final DateTime creadoEn;
  final bool leida;
  final int? referenciaId;

  const NotificationModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.creadoEn,
    required this.leida,
    required this.referenciaId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final created = json['creado_en'] ??
        json['created_at'] ??
        json['fecha'] ??
        json['timestamp'];

    DateTime parseDate(Object? v) {
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    int? parseId(Object? v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final payload = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : (json['payload'] is Map
            ? Map<String, dynamic>.from(json['payload'] as Map)
            : null);

    final refId = parseId(
          json['referencia_id'] ??
              json['objeto_id'] ??
              json['target_id'] ??
              json['resource_id'],
        ) ??
        parseId(payload?['id'] ??
            payload?['obra_id'] ??
            payload?['artwork_id'] ??
            payload?['auction_id'] ??
            payload?['subasta_id'] ??
            payload?['event_id'] ??
            payload?['evento_id'] ??
            payload?['order_id'] ??
            payload?['compra_id']);

    return NotificationModel(
      id: parseId(json['id']) ?? 0,
      tipo: (json['tipo'] ?? json['type'] ?? '').toString(),
      titulo: (json['titulo'] ?? json['title'] ?? 'Notificación').toString(),
      descripcion:
          (json['descripcion'] ?? json['body'] ?? json['message'] ?? '')
              .toString(),
      creadoEn: parseDate(created),
      leida: (json['leida'] ?? json['read'] ?? false) == true,
      referenciaId: refId,
    );
  }
}

