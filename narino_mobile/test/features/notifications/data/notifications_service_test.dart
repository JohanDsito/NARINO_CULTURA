import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/constants/api_constants.dart';
import 'package:narino_cultura/core/network/api_client.dart';
import 'package:narino_cultura/features/notifications/data/notifications_service.dart';

// NotificationsService no permite inyectar un Dio propio (usa siempre
// `ApiClient.instance.dio`), así que se sigue el mismo enfoque que
// test/features/auth/data/auth_repository_test.dart: se inicializa el
// ApiClient real y se le reemplaza el httpClientAdapter por un doble de
// prueba en memoria, más un handler falso para el canal de
// flutter_secure_storage que usa AuthInterceptor en cada request.

const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void _installFakeSecureStorage() {
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
}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _installFakeSecureStorage();

  late _FakeHttpClientAdapter adapter;
  late NotificationsService service;

  setUpAll(() {
    ApiClient.instance.init();
  });

  setUp(() {
    adapter = _FakeHttpClientAdapter();
    ApiClient.instance.dio.httpClientAdapter = adapter;
    service = NotificationsService();
  });

  group('list', () {
    test('devuelve la lista cuando la respuesta es una lista plana',
        () async {
      adapter.stub(ApiConstants.notifications, statusCode: 200, data: [
        {'id': 1},
        {'id': 2},
      ]);

      final result = await service.list();

      expect(result, hasLength(2));
    });

    test('devuelve la lista de "results" cuando la respuesta es paginada',
        () async {
      adapter.stub(ApiConstants.notifications, statusCode: 200, data: {
        'results': [
          {'id': 1},
        ],
        'count': 1,
      });

      final result = await service.list();

      expect(result, hasLength(1));
    });

    test('devuelve lista vacía si la respuesta no es lista ni paginada',
        () async {
      adapter.stub(ApiConstants.notifications, statusCode: 200, data: {});

      final result = await service.list();

      expect(result, isEmpty);
    });

    test('devuelve lista vacía en un 404 en vez de lanzar', () async {
      adapter.stub(ApiConstants.notifications, statusCode: 404);

      final result = await service.list();

      expect(result, isEmpty);
    });

    test('propaga otros códigos de error', () async {
      adapter.stub(ApiConstants.notifications, statusCode: 500);

      await expectLater(service.list(), throwsA(isA<DioException>()));
    });
  });

  group('markRead', () {
    test('completa sin lanzar cuando el backend responde bien', () async {
      final path = ApiConstants.notificationRead.replaceFirst('{id}', '7');
      adapter.stub(path, statusCode: 200);

      await expectLater(service.markRead(7), completes);
    });

    test('ignora silenciosamente un 404', () async {
      final path = ApiConstants.notificationRead.replaceFirst('{id}', '7');
      adapter.stub(path, statusCode: 404);

      await expectLater(service.markRead(7), completes);
    });

    test('propaga otros códigos de error', () async {
      final path = ApiConstants.notificationRead.replaceFirst('{id}', '7');
      adapter.stub(path, statusCode: 500);

      await expectLater(service.markRead(7), throwsA(isA<DioException>()));
    });
  });

  group('readAll', () {
    test('completa sin lanzar cuando el backend responde bien', () async {
      adapter.stub(ApiConstants.notificationsReadAll, statusCode: 200);

      await expectLater(service.readAll(), completes);
    });

    test('ignora silenciosamente un 404', () async {
      adapter.stub(ApiConstants.notificationsReadAll, statusCode: 404);

      await expectLater(service.readAll(), completes);
    });

    test('propaga otros códigos de error', () async {
      adapter.stub(ApiConstants.notificationsReadAll, statusCode: 500);

      await expectLater(service.readAll(), throwsA(isA<DioException>()));
    });
  });

  group('getEventPreferences', () {
    test('devuelve el mapa de preferencias del backend', () async {
      adapter.stub(
        ApiConstants.eventNotificationPreferences,
        statusCode: 200,
        data: {'all_enabled': true, 'categories': <String, dynamic>{}},
      );

      final result = await service.getEventPreferences();

      expect(result['all_enabled'], isTrue);
    });

    test('propaga el error cuando el endpoint no existe (404)', () async {
      adapter.stub(ApiConstants.eventNotificationPreferences, statusCode: 404);

      // A diferencia de list/markRead/readAll, este método NO absorbe el
      // 404 — el endpoint aún no existe en el backend (ver docs/backend-gaps.md)
      // y por ahora la llamada simplemente falla.
      await expectLater(
        service.getEventPreferences(),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('saveEventPreferences', () {
    test('completa sin lanzar cuando el backend responde bien', () async {
      adapter.stub(ApiConstants.eventNotificationPreferences, statusCode: 200);

      await expectLater(
        service.saveEventPreferences({'all_enabled': false}),
        completes,
      );
    });

    test('propaga el error cuando el endpoint no existe (404)', () async {
      adapter.stub(ApiConstants.eventNotificationPreferences, statusCode: 404);

      await expectLater(
        service.saveEventPreferences({'all_enabled': false}),
        throwsA(isA<DioException>()),
      );
    });
  });
}
