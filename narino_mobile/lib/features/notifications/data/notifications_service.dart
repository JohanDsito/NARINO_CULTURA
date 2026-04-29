import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class NotificationsService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<dynamic>> list({bool? onlyUnread}) async {
    final qp = <String, dynamic>{};
    if (onlyUnread == true) qp['no_leidas'] = true;
    final res = await _dio.get(ApiConstants.notifications, queryParameters: qp);
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['results'] is List) return data['results'] as List;
    return const <dynamic>[];
  }

  Future<void> markRead(int id) async {
    final path = ApiConstants.notificationRead.replaceFirst('{id}', '$id');
    await _dio.patch(path, data: {});
  }

  Future<void> readAll() async {
    await _dio.post(ApiConstants.notificationsReadAll, data: {});
  }
}
