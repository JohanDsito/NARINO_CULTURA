import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
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

  Future<void> register({
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
  }

  Future<bool> hasToken() => StorageUtils.hasToken();

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get(ApiConstants.profile);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw FormatException(_parseDioError(e));
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(ApiConstants.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  /// Reenvía el correo de verificación. Se llama sin sesión (desde la
  /// pantalla de "revisa tu correo"), así que va el correo en el cuerpo.
  Future<void> resendVerification({required String email}) async {
    try {
      await _dio.post(ApiConstants.resendVerification, data: {'email': email});
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // Antes se ignoraban y la pantalla decía "reenviado" sin enviar nada.
      if (code == 404 || code == 405) {
        throw 'El reenvío todavía no está disponible.';
      }
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
    final code = e.response?.statusCode;
    final body = e.response?.data;

    if (code == 403 || code == 429) {
      return 'Hiciste demasiados intentos. Tu cuenta quedó bloqueada 15 minutos; intenta después.';
    }
    if (isRegister && code == 400 && body is Map && body.containsKey('email')) {
      return 'Ya existe una cuenta con este correo. Inicia sesión o recupera tu contraseña.';
    }
    if (!isRegister && (code == 400 || code == 401)) {
      return friendlyLoginMessage(ApiError.extractMessage(body));
    }
    return ApiError.message(e);
  }

  /// Traduce los mensajes del `LoginSerializer` del backend a textos que dicen
  /// qué hacer. Lo que no reconoce se muestra tal cual (ya viene de DRF, en español).
  static String friendlyLoginMessage(String? backend) {
    final text = backend?.toLowerCase() ?? '';
    if (text.isEmpty || text.contains('credenciales')) {
      return 'Correo o contraseña incorrectos. Revísalos o toca «¿Olvidaste tu contraseña?».';
    }
    if (text.contains('verificar')) {
      return 'Primero confirma tu correo: abre el enlace que te enviamos al registrarte.';
    }
    if (text.contains('inactivo')) {
      return 'Tu cuenta está desactivada. Escribe al equipo de Nariño Cultura para reactivarla.';
    }
    return backend!;
  }

  String _parseDioError(DioException e) =>
      ApiError.message(e, fallback: 'Solicitud inválida.');
}
