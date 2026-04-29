import 'package:dio/dio.dart';

import 'account_security_service.dart';

class ActiveSessionModel {
  final int id;
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
    final id = _asInt(json['id']) ?? 0;

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

class AccountSecurityRepository {
  AccountSecurityRepository({AccountSecurityService? service})
      : _service = service ?? AccountSecurityService();

  final AccountSecurityService _service;

  Future<void> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      await _service.changeEmail(newEmail: newEmail, password: password);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<List<ActiveSessionModel>> getActiveSessions() async {
    try {
      final list = await _service.getActiveSessions();
      return list
          .whereType<Map>()
          .map((e) => ActiveSessionModel.fromJson(e.cast<String, dynamic>()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<void> revokeSession(int id) async {
    try {
      await _service.revokeSession(id);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<void> revokeOtherSessions() async {
    try {
      await _service.revokeOtherSessions();
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<void> deleteAccount({required String password}) async {
    try {
      await _service.deleteAccount(password: password);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  String _parseDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar al servidor.';
    }

    final code = e.response?.statusCode;
    final body = e.response?.data;

    if (code == 400) {
      final msg = _extractMessage(body);
      if (msg != null && msg.isNotEmpty) return msg;
      return 'Solicitud inválida.';
    }
    if (code == 401) return 'Tu sesión expiró. Inicia sesión nuevamente.';
    if (code == 403) return 'No tienes permiso para realizar esta acción.';
    if (code == 404) return 'Recurso no encontrado.';

    final extracted = _extractMessage(body);
    if (extracted != null && extracted.isNotEmpty) return extracted;

    return 'Error inesperado. Intenta de nuevo.';
  }

  String? _extractMessage(Object? data) {
    if (data is Map) {
      final detail = data['detail']?.toString();
      if (detail != null && detail.isNotEmpty) return detail;

      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          final msg = value.first?.toString();
          if (msg != null && msg.isNotEmpty) return msg;
        }
      }
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '');
}

