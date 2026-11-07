import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/constants/api_constants.dart';
import 'package:narino_cultura/core/network/interceptors/auth_interceptor.dart';
import 'package:narino_cultura/core/utils/storage_utils.dart';

/// Responde 401 con el token viejo y 200 con el nuevo; cuenta los refresh.
class _Adapter implements HttpClientAdapter {
  int refrescos = 0;
  Map<String, dynamic> respuestaRefresh = {'access': 'nuevo'};

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
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return json(200, respuestaRefresh);
    }
    final auth = o.headers['Authorization'];
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

  test('sin rotación se conserva el refresh actual', () async {
    await dio.get('/a/');
    expect(await StorageUtils.getRefreshToken(), 'refresh-1');
  });
}
