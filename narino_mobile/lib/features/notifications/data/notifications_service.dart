import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class NotificationsService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<dynamic>> list({bool? onlyUnread}) async {
    try {
      final qp = <String, dynamic>{};
      if (onlyUnread == true) qp['unread'] = 'true';
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

  /// Número de notificaciones sin leer (`GET /notifications/unread-count/`).
  Future<int> unreadCount() async {
    final res = await _dio.get(ApiConstants.notificationsUnreadCount);
    final data = res.data;
    if (data is Map) {
      final v = data['unread'];
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  Future<void> markRead(String id) async {
    try {
      final path = ApiConstants.notificationRead.replaceFirst('{id}', id);
      await _dio.post(path, data: {});
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

  /// NOTA: el backend (HU-B09) expone la bandeja, pero NO un endpoint de
  /// preferencias por tipo de evento. Esta llamada falla con 404 hasta que se
  /// implemente; la pantalla de preferencias guarda localmente mientras tanto.
  Future<Map<String, dynamic>> getEventPreferences() async {
    final res =
        await _dio.get(ApiConstants.eventNotificationPreferences);
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<void> saveEventPreferences(Map<String, dynamic> data) async {
    await _dio.patch(ApiConstants.eventNotificationPreferences, data: data);
  }
}
