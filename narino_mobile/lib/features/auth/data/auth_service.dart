import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class AuthService {
  final Dio _dio;

  AuthService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      options:
          Options(extra: const {'__skipAuth': true, '__skipAuthRefresh': true}),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'first_name': firstName,
        'email': email,
        'password': password,
        'role': role,
      },
      options:
          Options(extra: const {'__skipAuth': true, '__skipAuthRefresh': true}),
    );
    return response.data as Map<String, dynamic>;
  }
}
