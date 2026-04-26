enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? successMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        successMessage: successMessage,
      );

  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
