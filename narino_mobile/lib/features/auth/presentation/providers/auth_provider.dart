import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
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
        role: user.rol,
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

  Future<void> register({
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
      await _repository.register(
        firstName: firstName,
        email: email,
        password: password,
        role: role,
      );
      state = state.copyWith(
        status: AuthStatus.registrationPending,
        errorMessage: null,
        successMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapError(e),
        successMessage: null,
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void forceSignOut() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  /// El repositorio ya traduce los errores de la API a `FormatException`
  /// con un mensaje para el usuario; esto cubre lo que llegue sin traducir.
  String _mapError(Object error) {
    if (error is FormatException) return error.message;
    if (error is DioException) return ApiError.message(error);
    return ApiError.inesperado;
  }
}
