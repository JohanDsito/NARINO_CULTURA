import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narino_cultura/core/constants/api_constants.dart';
import 'package:narino_cultura/core/network/api_client.dart';
import 'package:narino_cultura/features/auth/data/auth_repository.dart';
import 'package:narino_cultura/features/auth/data/auth_service.dart';

class _MockAuthService extends Mock implements AuthService {}

/// `StorageUtils` (usado por `AuthInterceptor` en cada request) habla con
/// `flutter_secure_storage` a través de este MethodChannel. En un test de
/// widgets/unitario normal no hay ninguna implementación nativa registrada
/// del otro lado, así que las llamadas se quedan colgadas indefinidamente en
/// vez de fallar rápido. Se instala un handler falso, en memoria, para que
/// esas llamadas respondan al instante y para no tocar jamás el
/// almacenamiento seguro real del sistema operativo.
const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// Instala el handler falso y devuelve el mapa en memoria que lo respalda,
/// para que los tests puedan sembrar/inspeccionar tokens directamente
/// (usando las mismas claves que [StorageUtils]: 'jwt_access_token' /
/// 'jwt_refresh_token').
Map<String, String> _installFakeSecureStorage() {
  final storage = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorageChannel, (call) async {
    final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
    switch (call.method) {
      case 'read':
        return storage[args['key']];
      case 'write':
        storage[args['key'] as String] = args['value'] as String;
        return null;
      case 'delete':
        storage.remove(args['key']);
        return null;
      case 'deleteAll':
        storage.clear();
        return null;
      case 'containsKey':
        return storage.containsKey(args['key']);
      case 'readAll':
        return storage;
      default:
        return null;
    }
  });
  return storage;
}

/// [AuthRepository] no permite inyectar un [Dio] propio: para getMe(),
/// forgotPassword() y resendVerification() usa siempre
/// `ApiClient.instance.dio` a través del getter privado `_dio`. Para probar
/// esos métodos sin tocar la red real, inicializamos el `ApiClient` real
/// (que instala su `AuthInterceptor` normalmente) y le reemplazamos el
/// `httpClientAdapter` por este doble de prueba, que responde con datos
/// fijos según el path solicitado. Esto es, en la práctica, una prueba de
/// integración liviana en vez de un mock puro con mocktail, tal como sugiere
/// la tarea para los métodos que no pasan por `AuthService`.
class _FakeHttpClientAdapter implements HttpClientAdapter {
  final Map<String, _Stub> _stubs = {};

  void stub(String path, {required int statusCode, Object? data}) {
    _stubs[path] = _Stub(statusCode: statusCode, data: data);
  }

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final stub = _stubs[options.uri.path];
    if (stub == null) {
      throw StateError(
        'No hay stub configurado para ${options.uri.path} en este test.',
      );
    }
    final body = stub.data == null ? '' : jsonEncode(stub.data);
    return ResponseBody.fromString(
      body,
      stub.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _Stub {
  _Stub({required this.statusCode, this.data});
  final int statusCode;
  final Object? data;
}

Map<String, dynamic> _userJson() => {
      'id': '1',
      'email': 'ana@test.com',
      'nombre': 'Ana',
      'rol': 'artista',
      'is_verified': true,
    };

/// Construye un [DioException] como el que lanzaría Dio ante una respuesta
/// HTTP con [statusCode], para probar el manejo de errores del repositorio
/// en los métodos que sí van a través de [AuthService] (login/register).
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
  TestWidgetsFlutterBinding.ensureInitialized();
  final fakeStorage = _installFakeSecureStorage();

  group('getMe / forgotPassword / resendVerification (usan _dio)', () {
    late _FakeHttpClientAdapter adapter;
    late AuthRepository repo;

    setUpAll(() {
      // ApiClient es un singleton con un campo `late final Dio`, así que
      // solo puede inicializarse una vez por proceso de test (una segunda
      // llamada a init() lanzaría LateInitializationError). Crea el Dio
      // real con su AuthInterceptor real ya conectado.
      ApiClient.instance.init();
    });

    setUp(() {
      // En cada test se reemplaza el adaptador HTTP por uno nuevo para no
      // golpear la red real. El almacenamiento seguro que usa el
      // AuthInterceptor en cada request ya está falseado en memoria por
      // _installFakeSecureStorage(), así que tampoco toca el sistema real.
      adapter = _FakeHttpClientAdapter();
      ApiClient.instance.dio.httpClientAdapter = adapter;
      repo = AuthRepository(service: _MockAuthService());
    });

    group('getMe', () {
      test('mapea la respuesta exitosa a UserModel', () async {
        adapter.stub(ApiConstants.profile, statusCode: 200, data: _userJson());

        final user = await repo.getMe();

        expect(user.id, '1');
        expect(user.email, 'ana@test.com');
        expect(user.nombre, 'Ana');
        expect(user.rol, 'artista');
        expect(user.isVerified, isTrue);
      });

      test('traduce un 404 a FormatException con mensaje entendible',
          () async {
        adapter.stub(ApiConstants.profile, statusCode: 404);

        await expectLater(
          repo.getMe(),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Recurso no encontrado.',
            ),
          ),
        );
      });

      test('traduce un 400 con detalle de campo a FormatException', () async {
        adapter.stub(ApiConstants.profile, statusCode: 400, data: {
          'detail': 'Solicitud incorrecta.',
        });

        await expectLater(
          repo.getMe(),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Solicitud incorrecta.',
            ),
          ),
        );
      });
    });

    group('forgotPassword', () {
      test('completa sin lanzar cuando el backend responde 200', () async {
        adapter.stub(ApiConstants.forgotPassword, statusCode: 200);

        await expectLater(repo.forgotPassword('ana@test.com'), completes);
      });

      test('propaga un mensaje de error (String) cuando el backend falla',
          () async {
        adapter.stub(ApiConstants.forgotPassword, statusCode: 403);

        await expectLater(
          repo.forgotPassword('ana@test.com'),
          throwsA('No tienes permiso para realizar esta acción.'),
        );
      });

      test('usa el detail del body como mensaje en un error 400', () async {
        adapter.stub(ApiConstants.forgotPassword, statusCode: 400, data: {
          'email': ['Correo inválido.'],
        });

        await expectLater(
          repo.forgotPassword('no-es-un-correo'),
          throwsA('Correo inválido.'),
        );
      });
    });

    group('resendVerification', () {
      test('completa sin lanzar cuando el backend responde 200', () async {
        adapter.stub(ApiConstants.resendVerification, statusCode: 200);

        await expectLater(repo.resendVerification(), completes);
      });

      test('ignora silenciosamente un 404 (endpoint no disponible)',
          () async {
        adapter.stub(ApiConstants.resendVerification, statusCode: 404);

        await expectLater(repo.resendVerification(), completes);
      });

      test('ignora silenciosamente un 405 (método no permitido)', () async {
        adapter.stub(ApiConstants.resendVerification, statusCode: 405);

        await expectLater(repo.resendVerification(), completes);
      });

      test('propaga un mensaje de error (String) en otros códigos', () async {
        adapter.stub(ApiConstants.resendVerification, statusCode: 403);

        await expectLater(
          repo.resendVerification(),
          throwsA('No tienes permiso para realizar esta acción.'),
        );
      });
    });

    group('hasToken', () {
      test('retorna un booleano sin lanzar excepciones', () async {
        expect(await repo.hasToken(), isA<bool>());
      });
    });
  });

  group('login / register (usan AuthService)', () {
    late _MockAuthService service;
    late AuthRepository repo;

    setUp(() {
      service = _MockAuthService();
      repo = AuthRepository(service: service);
    });

    group('login', () {
      // Estos casos ocurren completamente antes de tocar StorageUtils/_dio
      // (el servicio mockeado falla o devuelve tokens inválidos), así que
      // solo dependen de AuthService. El camino 100% exitoso de login()
      // (guarda tokens y luego pide el perfil con _dio) se cubre más abajo,
      // en el grupo "login (camino feliz) y logout", junto con el
      // almacenamiento seguro falseado en memoria.
      test(
          'lanza FormatException con mensaje traducido si el servicio falla',
          () async {
        when(() => service.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(_httpError(401));

        await expectLater(
          repo.login(email: 'ana@test.com', password: 'mala-clave'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Correo o contraseña incorrectos.',
            ),
          ),
        );
      });

      test('lanza FormatException cuando la respuesta no trae tokens',
          () async {
        when(() => service.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => <String, dynamic>{});

        await expectLater(
          repo.login(email: 'ana@test.com', password: '12345678'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Respuesta inválida del servidor (tokens).',
            ),
          ),
        );
      });

      test('lanza FormatException cuando falta el refresh token', () async {
        when(() => service.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => {'access': 'token-de-acceso'});

        await expectLater(
          repo.login(email: 'ana@test.com', password: '12345678'),
          throwsA(isA<FormatException>()),
        );
      });

      test('traduce un bloqueo temporal (403/429) a mensaje entendible',
          () async {
        when(() => service.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(_httpError(429));

        await expectLater(
          repo.login(email: 'ana@test.com', password: '12345678'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Cuenta bloqueada temporalmente. Intenta en 15 minutos.',
            ),
          ),
        );
      });

      test('traduce un error de conexión a mensaje entendible', () async {
        when(() => service.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(_connectionError());

        await expectLater(
          repo.login(email: 'ana@test.com', password: '12345678'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'No se pudo conectar al servidor. Verifica tu conexión.',
            ),
          ),
        );
      });
    });

    group('register', () {
      test('completa sin lanzar cuando el servicio responde bien', () async {
        when(() => service.register(
              firstName: any(named: 'firstName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: any(named: 'role'),
            )).thenAnswer((_) async => <String, dynamic>{});

        await expectLater(
          repo.register(
            firstName: 'Ana',
            email: 'ana@test.com',
            password: '12345678',
            role: 'artista',
          ),
          completes,
        );
      });

      test('traduce un 400 con conflicto de email a mensaje específico',
          () async {
        when(() => service.register(
              firstName: any(named: 'firstName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: any(named: 'role'),
            )).thenThrow(_httpError(400, data: {
              'email': ['Ya existe un usuario con este correo.'],
            }));

        await expectLater(
          repo.register(
            firstName: 'Ana',
            email: 'ana@test.com',
            password: '12345678',
            role: 'artista',
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Ya existe una cuenta con este correo electrónico.',
            ),
          ),
        );
      });

      test('extrae el primer mensaje de error en un 400 sin conflicto de email',
          () async {
        when(() => service.register(
              firstName: any(named: 'firstName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: any(named: 'role'),
            )).thenThrow(_httpError(400, data: {
              'password': ['La contraseña es demasiado corta.'],
            }));

        await expectLater(
          repo.register(
            firstName: 'Ana',
            email: 'ana@test.com',
            password: '123',
            role: 'artista',
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'La contraseña es demasiado corta.',
            ),
          ),
        );
      });

      test('traduce un error de conexión a mensaje entendible', () async {
        when(() => service.register(
              firstName: any(named: 'firstName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: any(named: 'role'),
            )).thenThrow(_connectionError());

        await expectLater(
          repo.register(
            firstName: 'Ana',
            email: 'ana@test.com',
            password: '12345678',
            role: 'artista',
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'No se pudo conectar al servidor. Verifica tu conexión.',
            ),
          ),
        );
      });
    });
  });

  group('login (camino feliz) y logout (usan AuthService + _dio + storage)',
      () {
    late _MockAuthService service;
    late _FakeHttpClientAdapter adapter;
    late AuthRepository repo;

    setUp(() {
      fakeStorage.clear();
      service = _MockAuthService();
      adapter = _FakeHttpClientAdapter();
      ApiClient.instance.dio.httpClientAdapter = adapter;
      repo = AuthRepository(service: service);
    });

    group('login', () {
      test('guarda los tokens y devuelve el perfil autenticado', () async {
        when(() => service.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => {
              'access': 'access-123',
              'refresh': 'refresh-456',
            });
        adapter.stub(ApiConstants.profile, statusCode: 200, data: _userJson());

        final user =
            await repo.login(email: 'ana@test.com', password: '12345678');

        expect(user.email, 'ana@test.com');
        expect(user.rol, 'artista');
        expect(fakeStorage['jwt_access_token'], 'access-123');
        expect(fakeStorage['jwt_refresh_token'], 'refresh-456');
      });

      test(
          'lanza FormatException si falla la carga del perfil tras autenticar',
          () async {
        when(() => service.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => {
              'access': 'access-123',
              'refresh': 'refresh-456',
            });
        adapter.stub(ApiConstants.profile, statusCode: 404);

        await expectLater(
          repo.login(email: 'ana@test.com', password: '12345678'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Recurso no encontrado.',
            ),
          ),
        );
        // Los tokens ya se habían guardado antes de que fallara la carga
        // del perfil, tal como hace el código real.
        expect(fakeStorage['jwt_access_token'], 'access-123');
      });
    });

    group('logout', () {
      test('no llama al backend si no hay refresh token guardado', () async {
        await expectLater(repo.logout(), completes);

        expect(fakeStorage.containsKey('jwt_access_token'), isFalse);
        expect(fakeStorage.containsKey('jwt_refresh_token'), isFalse);
      });

      test('envía el refresh token al backend y limpia el storage', () async {
        fakeStorage['jwt_access_token'] = 'access-123';
        fakeStorage['jwt_refresh_token'] = 'refresh-456';
        adapter.stub(ApiConstants.logout, statusCode: 200);

        await repo.logout();

        expect(fakeStorage.containsKey('jwt_access_token'), isFalse);
        expect(fakeStorage.containsKey('jwt_refresh_token'), isFalse);
      });

      test('limpia el storage incluso si el backend falla al cerrar sesión',
          () async {
        fakeStorage['jwt_access_token'] = 'access-123';
        fakeStorage['jwt_refresh_token'] = 'refresh-456';
        adapter.stub(ApiConstants.logout, statusCode: 500);

        await expectLater(repo.logout(), completes);

        expect(fakeStorage.containsKey('jwt_access_token'), isFalse);
        expect(fakeStorage.containsKey('jwt_refresh_token'), isFalse);
      });
    });
  });
}
