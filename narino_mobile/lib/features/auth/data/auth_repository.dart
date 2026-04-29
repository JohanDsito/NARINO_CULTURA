import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/storage_utils.dart';
import '../domain/user_model.dart';
import 'auth_service.dart';

class AuthRepository {
  AuthRepository({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;
  Dio get _dio => ApiClient.instance.dio;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final tokens = await _service.login(email: email, password: password);

    final access = tokens['access']?.toString();
    final refresh = tokens['refresh']?.toString();

    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      throw const FormatException('Respuesta inválida del servidor (tokens).');
    }

    await StorageUtils.saveTokens(accessToken: access, refreshToken: refresh);
  }

  Future<UserModel> register({
    required String nombre,
    required String email,
    required String password,
    required String rol,
  }) async {
    final json = await _service.register(
      nombre: nombre,
      email: email,
      password: password,
      rol: rol,
    );

    final user = UserModel.fromJson(json);
    await login(email: email, password: password);
    return user;
  }

  Future<bool> hasToken() => StorageUtils.hasToken();

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(ApiConstants.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<void> resendVerification() async {
    try {
      await _dio.post(ApiConstants.resendVerification, data: {});
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await StorageUtils.getRefreshToken();
      if (refresh != null) {
        await _dio.post(ApiConstants.logout, data: {'refresh': refresh});
      }
    } catch (_) {
    } finally {
      await StorageUtils.clearTokens();
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
