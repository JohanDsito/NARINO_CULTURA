import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';
import '../../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository)
      : super(const AuthState(status: AuthStatus.unauthenticated));

  final AuthRepository _repository;

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final user = await _repository.login(email: email, password: password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        errorMessage: null,
        successMessage: null,
      );
      return user;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapError(e),
        successMessage: null,
      );
      return null;
    }
  }

  Future<UserModel?> register({
    required String firstName,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final user = await _repository.register(
        firstName: firstName,
        email: email,
        password: password,
        role: role,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        errorMessage: null,
        successMessage: null,
      );
      return user;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapError(e),
        successMessage: null,
      );
      return null;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
      successMessage: null,
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  String _mapError(Object error) {
    if (error is FormatException) return error.message;

    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;

      if (status == 429) {
        return 'Demasiados intentos. Tu cuenta fue bloqueada por 15 minutos. Intenta más tarde.';
      }

      if (status == 401) {
        return 'Credenciales incorrectas. Verifica tu correo y contraseña.';
      }

      if (status == 400 && data is Map<String, dynamic>) {
        if (data.containsKey('email')) {
          return 'Este correo ya está registrado.';
        }
        if (data.containsKey('detail')) {
          final detail = data['detail']?.toString();
          if (detail != null && detail.isNotEmpty) return detail;
        }
      }

      if (status == 403) {
        final message = _extractMessage(data);
        if (message != null) {
          final lower = message.toLowerCase();
          if (lower.contains('blocked') ||
              lower.contains('bloque') ||
              lower.contains('throttle') ||
              lower.contains('too many')) {
            return 'Demasiados intentos. Tu cuenta fue bloqueada por 15 minutos. Intenta más tarde.';
          }
          return message;
        }
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Tiempo de espera agotado. Verifica tu conexión e intenta nuevamente.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'No se pudo conectar con el servidor. Verifica tu conexión.';
      }

      final message = _extractMessage(data);
      if (message != null && message.isNotEmpty) return message;

      return 'Ocurrió un error al comunicar con el servidor.';
    }

    return 'Ocurrió un error inesperado.';
  }

  String? _extractMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail']?.toString();
      if (detail != null && detail.isNotEmpty) return detail;

      final nonField = data['non_field_errors'];
      if (nonField is List && nonField.isNotEmpty) {
        final msg = nonField.first?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }

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
