import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notifications_service.dart';
import '../../domain/notification_model.dart';

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});

final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationsNotifier(ref.read(notificationsServiceProvider));
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  // Se recalcula cada vez que cambia la bandeja cargada.
  ref.watch(notificationsProvider);
  final service = ref.read(notificationsServiceProvider);
  try {
    return await service.unreadCount();
  } catch (_) {
    return 0;
  }
});

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  NotificationsNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  final NotificationsService _service;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final raw = await _service.list();
      final items = raw
          .whereType<Map>()
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = AsyncValue.data(items);
    } on DioException catch (e, st) {
      state = AsyncValue.error(_parseDioError(e), st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Marca una notificación como leída de forma optimista; si el servidor
  /// falla se recarga la bandeja para no dejar un estado falso.
  Future<void> markRead(String id) async {
    final current = state.valueOrNull ?? const <NotificationModel>[];
    final target = current.where((n) => n.id == id).firstOrNull;
    if (id.isEmpty || target == null || target.leida) return;
    state = AsyncValue.data([
      for (final n in current) n.id == id ? n.copyWith(leida: true) : n,
    ]);
    try {
      await _service.markRead(id);
    } catch (_) {
      await load();
    }
  }

  Future<void> readAll() async {
    final current = state.valueOrNull ?? const <NotificationModel>[];
    state = AsyncValue.data([for (final n in current) n.copyWith(leida: true)]);
    try {
      await _service.readAll();
    } catch (_) {
      await load();
    }
  }

  String _parseDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar al servidor.';
    }
    final code = e.response?.statusCode;
    final body = e.response?.data;
    if (code == 401) return 'Tu sesión expiró. Inicia sesión nuevamente.';
    if (code == 403) return 'No tienes permiso para realizar esta acción.';
    if (code == 404) return 'Recurso no encontrado.';

    final extracted = _extractMessage(body);
    if (extracted != null && extracted.isNotEmpty) return extracted;
    return 'Error inesperado. Intenta de nuevo.';
  }

  String? _extractMessage(Object? data) {
    if (data is Map) {
      final detail = data['detail']?.toString();
      if (detail != null && detail.isNotEmpty) return detail;
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          final msg = value.first?.toString();
          if (msg != null && msg.isNotEmpty) return msg;
        }
      }
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}

