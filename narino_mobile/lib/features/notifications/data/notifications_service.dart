import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class NotificationsService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<dynamic>> list({bool? onlyUnread}) async {
    try {
      final qp = <String, dynamic>{};
      if (onlyUnread == true) qp['no_leidas'] = true;
      final res =
          await _dio.get(ApiConstants.notifications, queryParameters: qp);
      final data = res.data;
      if (data is List) return data;
      if (data is Map && data['results'] is List) {
        return data['results'] as List;
      }
      return const <dynamic>[];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const <dynamic>[];
      rethrow;
    }
  }

  Future<void> markRead(int id) async {
    try {
      final path = ApiConstants.notificationRead.replaceFirst('{id}', '$id');
      await _dio.patch(path, data: {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
  }

  Future<void> readAll() async {
    try {
      await _dio.post(ApiConstants.notificationsReadAll, data: {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
  }
}
