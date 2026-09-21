import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/auth/domain/auth_state.dart';

void main() {
  group('AuthState.copyWith', () {
    test('actualiza status y preserva role cuando no se especifica', () {
      const original = AuthState(status: AuthStatus.loading, role: 'artista');

      final updated = original.copyWith(status: AuthStatus.authenticated);

      expect(updated.status, AuthStatus.authenticated);
      expect(updated.role, 'artista');
    });

    test('limpia errorMessage y successMessage si no se pasan explícitamente',
        () {
      const original = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Algo falló',
        successMessage: 'Ok',
      );

      final updated = original.copyWith(status: AuthStatus.initial);

      expect(updated.errorMessage, isNull);
      expect(updated.successMessage, isNull);
    });

    test('permite fijar un nuevo errorMessage/successMessage explícito', () {
      const original = AuthState();

      final updated = original.copyWith(
        errorMessage: 'error nuevo',
        successMessage: 'éxito nuevo',
      );

      expect(updated.errorMessage, 'error nuevo');
      expect(updated.successMessage, 'éxito nuevo');
    });

    test('role se reemplaza cuando se especifica uno nuevo', () {
      const original = AuthState(role: 'comprador');

      final updated = original.copyWith(role: 'artista');

      expect(updated.role, 'artista');
    });
  });

  group('AuthState.isLoading', () {
    test('es true solo cuando status es loading', () {
      expect(const AuthState(status: AuthStatus.loading).isLoading, isTrue);
      expect(const AuthState(status: AuthStatus.initial).isLoading, isFalse);
      expect(
          const AuthState(status: AuthStatus.authenticated).isLoading,
          isFalse);
    });
  });

  group('AuthState.hasError', () {
    test('es false cuando errorMessage es null', () {
      expect(const AuthState().hasError, isFalse);
    });

    test('es false cuando errorMessage es una cadena vacía', () {
      expect(const AuthState(errorMessage: '').hasError, isFalse);
    });

    test('es true cuando hay un mensaje de error no vacío', () {
      expect(const AuthState(errorMessage: 'falló').hasError, isTrue);
    });
  });

  group('AuthState.isArtista', () {
    test('es true sin importar mayúsculas/minúsculas', () {
      expect(const AuthState(role: 'Artista').isArtista, isTrue);
      expect(const AuthState(role: 'ARTISTA').isArtista, isTrue);
      expect(const AuthState(role: 'artista').isArtista, isTrue);
    });

    test('es false para otros roles o cuando role es null', () {
      expect(const AuthState(role: 'comprador').isArtista, isFalse);
      expect(const AuthState().isArtista, isFalse);
    });
  });
}
