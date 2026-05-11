import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'interceptors/auth_interceptor.dart';

/// Cliente HTTP centralizado de la app basado en Dio.
///
/// Usar siempre `ApiClient.instance.dio` para todas las llamadas HTTP para
/// garantizar que el interceptor JWT esté activo y la configuración sea
/// consistente en toda la aplicación.
class ApiClient {
  ApiClient._();

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  late final Dio _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  Dio get dio => _dio;
}
