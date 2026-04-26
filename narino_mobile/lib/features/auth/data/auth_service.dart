import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';

class AuthService {
  final Dio _dio;

  AuthService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout:
                    const Duration(milliseconds: ApiConstants.connectTimeout),
                receiveTimeout:
                    const Duration(milliseconds: ApiConstants.receiveTimeout),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String nombre,
    required String email,
    required String password,
    required String rol,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'nombre': nombre,
        'email': email,
        'password': password,
        'rol': rol,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
