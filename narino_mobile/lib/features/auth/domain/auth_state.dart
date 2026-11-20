enum AuthStatus { initial, loading, authenticated, unauthenticated, error, registrationPending }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? successMessage;
  final String? role;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.role,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? successMessage,
    String? role,
  }) =>
      AuthState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        successMessage: successMessage,
        role: role ?? this.role,
      );

  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  bool get isArtista => role?.toLowerCase() == 'artista';
}
