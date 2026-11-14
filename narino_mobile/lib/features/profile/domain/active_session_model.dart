/// Modelo de dominio para representar una sesión activa del usuario.
class ActiveSessionModel {
  final String id;
  final String device;
  final DateTime createdAt;
  final bool isCurrent;

  const ActiveSessionModel({
    required this.id,
    required this.device,
    required this.createdAt,
    required this.isCurrent,
  });

  factory ActiveSessionModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';

    final device = (json['dispositivo'] ??
            json['device'] ??
            json['user_agent'] ??
            json['userAgent'] ??
            json['ip'] ??
            'Dispositivo')
        .toString();

    final isCurrent = (json['is_current'] ??
            json['isCurrent'] ??
            json['current'] ??
            json['actual'] ??
            false) ==
        true;

    final rawDate = json['created_at'] ??
        json['createdAt'] ??
        json['login_at'] ??
        json['loginAt'] ??
        json['last_seen'] ??
        json['lastSeen'] ??
        json['fecha'];

    DateTime createdAt = DateTime.now();
    final parsed = DateTime.tryParse(rawDate?.toString() ?? '');
    if (parsed != null) {
      createdAt = parsed;
    } else {
      final fecha = json['fecha']?.toString();
      final hora = json['hora']?.toString();
      final combined = (fecha != null && hora != null) ? '$fecha $hora' : null;
      final parsed2 = DateTime.tryParse(combined ?? '');
      if (parsed2 != null) createdAt = parsed2;
    }

    return ActiveSessionModel(
      id: id,
      device: device,
      createdAt: createdAt,
      isCurrent: isCurrent,
    );
  }
}
