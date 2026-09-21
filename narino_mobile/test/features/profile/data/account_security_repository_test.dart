import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narino_cultura/features/profile/data/account_security_repository.dart';
import 'package:narino_cultura/features/profile/data/account_security_service.dart';

class _MockAccountSecurityService extends Mock
    implements AccountSecurityService {}

/// Construye un [DioException] como el que lanzaría Dio ante una respuesta
/// HTTP con [statusCode], para probar el manejo de errores del repositorio.
DioException _httpError(int statusCode, {Object? data}) {
  final options = RequestOptions(path: '/test');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
  );
}

DioException _connectionError() => DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionError,
    );

void main() {
  late _MockAccountSecurityService service;
  late AccountSecurityRepository repo;

  setUp(() {
    service = _MockAccountSecurityService();
    repo = AccountSecurityRepository(service: service);
  });

  group('changeEmail', () {
    test('llama al servicio con el correo y la contraseña dados', () async {
      when(() => service.changeEmail(
            newEmail: any(named: 'newEmail'),
            password: any(named: 'password'),
          )).thenAnswer((_) async {});

      await repo.changeEmail(newEmail: 'nuevo@test.com', password: '1234');

      verify(() => service.changeEmail(
            newEmail: 'nuevo@test.com',
            password: '1234',
          )).called(1);
    });

    test('traduce un 400 con detalle a su mensaje', () async {
      when(() => service.changeEmail(
            newEmail: any(named: 'newEmail'),
            password: any(named: 'password'),
          )).thenThrow(_httpError(400, data: {
            'detail': 'La contraseña es incorrecta.',
          }));

      await expectLater(
        repo.changeEmail(newEmail: 'nuevo@test.com', password: 'mala'),
        throwsA('La contraseña es incorrecta.'),
      );
    });

    test('traduce un 400 sin detalle a un mensaje genérico', () async {
      when(() => service.changeEmail(
            newEmail: any(named: 'newEmail'),
            password: any(named: 'password'),
          )).thenThrow(_httpError(400));

      await expectLater(
        repo.changeEmail(newEmail: 'nuevo@test.com', password: 'mala'),
        throwsA('Solicitud inválida.'),
      );
    });
  });

  group('getActiveSessions', () {
    test('mapea y ordena las sesiones de más reciente a más antigua',
        () async {
      when(() => service.getActiveSessions()).thenAnswer((_) async => [
            {
              'id': 1,
              'device': 'Chrome / Windows',
              'created_at': '2025-01-01T00:00:00.000Z',
              'is_current': false,
            },
            {
              'id': 2,
              'device': 'App / Android',
              'created_at': '2025-06-01T00:00:00.000Z',
              'is_current': true,
            },
          ]);

      final sessions = await repo.getActiveSessions();

      expect(sessions, hasLength(2));
      expect(sessions.first.id, 2);
      expect(sessions.first.isCurrent, isTrue);
      expect(sessions.last.id, 1);
    });

    test('traduce un error de conexión a un mensaje entendible', () async {
      when(() => service.getActiveSessions()).thenThrow(_connectionError());

      await expectLater(
        repo.getActiveSessions(),
        throwsA('No se pudo conectar al servidor.'),
      );
    });
  });

  group('revokeSession', () {
    test('llama al servicio con el id dado', () async {
      when(() => service.revokeSession(any())).thenAnswer((_) async {});

      await repo.revokeSession(5);

      verify(() => service.revokeSession(5)).called(1);
    });

    test('traduce un 404 a un mensaje entendible', () async {
      when(() => service.revokeSession(any())).thenThrow(_httpError(404));

      await expectLater(
        repo.revokeSession(99),
        throwsA('Recurso no encontrado.'),
      );
    });
  });

  group('revokeOtherSessions', () {
    test('llama al servicio', () async {
      when(() => service.revokeOtherSessions()).thenAnswer((_) async {});

      await repo.revokeOtherSessions();

      verify(() => service.revokeOtherSessions()).called(1);
    });

    test('traduce un 401 a un mensaje entendible', () async {
      when(() => service.revokeOtherSessions()).thenThrow(_httpError(401));

      await expectLater(
        repo.revokeOtherSessions(),
        throwsA('Tu sesión expiró. Inicia sesión nuevamente.'),
      );
    });
  });

  group('deleteAccount', () {
    test('llama al servicio con la contraseña dada', () async {
      when(() => service.deleteAccount(password: any(named: 'password')))
          .thenAnswer((_) async {});

      await repo.deleteAccount(password: '1234');

      verify(() => service.deleteAccount(password: '1234')).called(1);
    });

    test('traduce un 403 a un mensaje entendible', () async {
      when(() => service.deleteAccount(password: any(named: 'password')))
          .thenThrow(_httpError(403));

      await expectLater(
        repo.deleteAccount(password: 'mala'),
        throwsA('No tienes permiso para realizar esta acción.'),
      );
    });

    test('traduce un error inesperado a un mensaje genérico', () async {
      when(() => service.deleteAccount(password: any(named: 'password')))
          .thenThrow(_httpError(500));

      await expectLater(
        repo.deleteAccount(password: '1234'),
        throwsA('Error inesperado. Intenta de nuevo.'),
      );
    });
  });
}
