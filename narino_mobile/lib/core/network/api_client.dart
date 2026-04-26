import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'interceptors/auth_interceptor.dart';

class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: {
        Headers.acceptHeader: Headers.jsonContentType,
        Headers.contentTypeHeader: Headers.jsonContentType,
      },
    );

    _dio.interceptors.addAll([
      AuthInterceptor(),
    ]);
  }

  final Dio _dio;

  Dio get dio => _dio;
}
