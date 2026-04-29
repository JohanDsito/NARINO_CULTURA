import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class AccountSecurityService {
  Dio get _dio => ApiClient.instance.dio;

  Future<void> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    await _dio.post(
      ApiConstants.changeEmail,
      data: {'new_email': newEmail, 'password': password},
    );
  }

  Future<List<dynamic>> getActiveSessions() async {
    final res = await _dio.get(ApiConstants.activeSessions);
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['results'] is List) return data['results'] as List;
    return const <dynamic>[];
  }

  Future<void> revokeSession(int id) async {
    final path = ApiConstants.sessionDetail.replaceAll('{id}', id.toString());
    await _dio.delete(path);
  }

  Future<void> revokeOtherSessions() async {
    await _dio.delete(ApiConstants.activeSessions);
  }

  Future<void> deleteAccount({required String password}) async {
    await _dio.post(
      ApiConstants.deleteAccount,
      data: {'password': password},
    );
  }
}

