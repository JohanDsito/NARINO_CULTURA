import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/constants/api_constants.dart';
import 'package:narino_cultura/core/network/interceptors/auth_interceptor.dart';
import 'package:narino_cultura/core/network/session_expiry.dart';
import 'package:narino_cultura/core/utils/storage_utils.dart';

/// Responde 401 con el token viejo y 200 con el nuevo; cuenta los refresh.
class _Adapter implements HttpClientAdapter {
  int refrescos = 0;
  Map<String, dynamic> respuestaRefresh = {'access': 'nuevo'};

  /// El refresh responde 401 (token de renovación vencido o en lista negra).
  bool refreshFalla = false;

  /// Código con que falla el refresh (el backend responde 400 si está en lista negra).
  int codigoFalla = 401;

  /// Refresh enviados en cada renovación, en orden.
  final List<String?> refreshEnviados = [];

  /// El reintento con el token nuevo se demora más que el timeout.
  bool reintentoLento = false;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? _, Future<void>? __) async {
    ResponseBody json(int code, Object data) => ResponseBody.fromString(
          jsonEncode(data),
          code,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
    if (o.path == ApiConstants.refreshToken) {
      refrescos++;
      refreshEnviados.add((o.data as Map)['refresh']?.toString());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (refreshFalla) return json(codigoFalla, {'detail': 'Token inválido.'});
      return json(200, respuestaRefresh);
    }
    final auth = o.headers['Authorization'];
    if (auth == 'Bearer nuevo' && reintentoLento) {
      throw DioException(requestOptions: o, type: DioExceptionType.receiveTimeout);
    }
    return auth == 'Bearer nuevo' ? json(200, {'ok': true}) : json(401, {'detail': 'expirado'});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _Adapter adapter;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'jwt_access_token': 'viejo',
      'jwt_refresh_token': 'refresh-1',
    });
    adapter = _Adapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(dio));
  });

  test('varias peticiones vencidas a la vez comparten una sola renovación', () async {
    final rs = await Future.wait([
      dio.get('/a/'),
      dio.get('/b/'),
      dio.get('/c/'),
    ]);
    expect(rs.every((r) => r.statusCode == 200), isTrue);
    expect(adapter.refrescos, 1);
  });

  test('si el backend rota el refresh, se guarda el nuevo', () async {
    adapter.respuestaRefresh = {'access': 'nuevo', 'refresh': 'refresh-2'};
    await dio.get('/a/');
    expect(await StorageUtils.getRefreshToken(), 'refresh-2');
  });

  test('una segunda renovación envía el refresh rotado, no el original', () async {
    adapter.respuestaRefresh = {'access': 'nuevo', 'refresh': 'refresh-2'};
    await dio.get('/a/');
    // El access guardado vuelve a vencer: fuerza otra renovación.
    await StorageUtils.saveTokens(accessToken: 'viejo', refreshToken: 'refresh-2');
    await dio.get('/b/');
    expect(adapter.refreshEnviados, ['refresh-1', 'refresh-2']);
  });

  test('si el refresh viene en lista negra (400), cierra la sesión', () async {
    adapter.refreshFalla = true;
    adapter.codigoFalla = 400;
    final antes = SessionExpiry.notifier.value;

    await expectLater(dio.get('/a/'), throwsA(isA<DioException>()));

    expect(await StorageUtils.hasToken(), isFalse);
    expect(SessionExpiry.notifier.value, antes + 1);
  });

  test('sin rotación se conserva el refresh actual', () async {
    await dio.get('/a/');
    expect(await StorageUtils.getRefreshToken(), 'refresh-1');
  });

  // MO-SEG-04: la sesión terminó de verdad → se borran los tokens y se avisa.
  test('si la renovación falla, borra los tokens y avisa que la sesión expiró',
      () async {
    adapter.refreshFalla = true;
    final antes = SessionExpiry.notifier.value;

    await expectLater(dio.get('/a/'), throwsA(isA<DioException>()));

    expect(await StorageUtils.hasToken(), isFalse);
    expect(SessionExpiry.notifier.value, antes + 1);
    expect(SessionExpiry.consumeMessage(), isTrue);
    expect(SessionExpiry.consumeMessage(), isFalse, reason: 'se muestra una vez');
  });

  // MO-LOAD-02: un timeout después de renovar no debe sacar a la persona.
  test('si el reintento falla por tiempo agotado, la sesión se conserva',
      () async {
    adapter.reintentoLento = true;
    final antes = SessionExpiry.notifier.value;

    await expectLater(
      dio.get('/a/'),
      throwsA(isA<DioException>().having(
          (e) => e.type, 'type', DioExceptionType.receiveTimeout)),
    );

    expect(await StorageUtils.getAccessToken(), 'nuevo');
    expect(SessionExpiry.notifier.value, antes);
  });

  test('sin sesión previa, un 401 no dispara el aviso de expiración', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final antes = SessionExpiry.notifier.value;

    await expectLater(dio.get('/a/'), throwsA(isA<DioException>()));

    expect(SessionExpiry.notifier.value, antes);
  });
}
