import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
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

  String _parseDioError(DioException e) =>
      ApiError.message(e, fallback: 'Solicitud inválida.');
}
