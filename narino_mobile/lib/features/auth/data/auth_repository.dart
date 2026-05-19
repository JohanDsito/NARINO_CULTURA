import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/storage_utils.dart';
import '../domain/user_model.dart';
import 'auth_service.dart';

/// Repositorio de autenticación: encapsula login/registro/logout y utilidades
/// relacionadas con la sesión (tokens, reintentos y endpoints de auth).
class AuthRepository {
  AuthRepository({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;
  Dio get _dio => ApiClient.instance.dio;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> tokens;
    try {
      tokens = await _service.login(email: email, password: password);
    } on DioException catch (e) {
      throw FormatException(_parseAuthError(e));
    }

    final access = tokens['access']?.toString();
    final refresh = tokens['refresh']?.toString();

    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      throw const FormatException('Respuesta inválida del servidor (tokens).');
    }

    await StorageUtils.saveTokens(accessToken: access, refreshToken: refresh);

    try {
      final meResponse = await _dio.get(ApiConstants.profile);
      return UserModel.fromJson(meResponse.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw FormatException(_parseDioError(e));
    }
  }

  Future<UserModel> register({
    required String firstName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await _service.register(
        firstName: firstName,
        email: email,
        password: password,
        role: role,
      );
    } on DioException catch (e) {
      throw FormatException(_parseAuthError(e, isRegister: true));
    }

    return login(email: email, password: password);
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
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) return;
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

  String _parseAuthError(DioException e, {bool isRegister = false}) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar al servidor. Verifica tu conexión.';
    }

    final code = e.response?.statusCode;
    final body = e.response?.data;

    if (code == 401) return 'Correo o contraseña incorrectos.';
    if (code == 403 || code == 429) {
      return 'Cuenta bloqueada temporalmente. Intenta en 15 minutos.';
    }

    if (isRegister && code == 400 && body is Map) {
      if (body.containsKey('email')) {
        return 'Ya existe una cuenta con este correo electrónico.';
      }
    }

    final extracted = _extractMessage(body);
    if (extracted != null && extracted.isNotEmpty) return extracted;

    return 'Error inesperado. Intenta de nuevo.';
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
