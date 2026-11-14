import 'package:dio/dio.dart';

import '../domain/active_session_model.dart';
import 'account_security_service.dart';

export '../domain/active_session_model.dart';

/// Repositorio de seguridad de cuenta: cambio de correo, sesiones activas y eliminación de cuenta.
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

  Future<void> revokeSession(String id) async {
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

  Future<void> changePassword({
    required String current,
    required String nueva,
  }) async {
    try {
      await _service.changePassword(current: current, nueva: nueva);
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
