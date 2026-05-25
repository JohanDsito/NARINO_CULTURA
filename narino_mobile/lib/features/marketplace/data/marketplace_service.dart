import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class MarketplaceService {
  Dio get _dio => ApiClient.instance.dio;

  // ── helpers ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _artworkDetail(String artworkId) async {
    try {
      final r = await _dio.get(
        ApiConstants.artworkDetail.replaceFirst('{id}', artworkId),
      );
      return r.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  String _nameFromSlug(String? slug) {
    if (slug == null || slug.isEmpty) return '';
    return slug
        .split('-')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // ── carrito ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> getCart() async {
    final r = await _dio.get(ApiConstants.cart);
    final data = r.data;
    final List<dynamic> raw;
    if (data is List) {
      raw = data;
    } else if (data is Map) {
      raw = (data['items'] as List?) ?? (data['results'] as List?) ?? [];
    } else {
      return [];
    }

    final enriched = <Map<String, dynamic>>[];
    for (final item in raw) {
      final base = Map<String, dynamic>.from(item as Map);
      final artworkId = base['artwork']?.toString() ?? '';
      if (artworkId.isNotEmpty) {
        final artwork = await _artworkDetail(artworkId);
        if (artwork != null) {
          final slug = artwork['artist_slug']?.toString() ?? '';
          base['artista_nombre'] =
              artwork['artista_nombre']?.toString() ?? _nameFromSlug(slug);
          base['imagen_url'] = artwork['main_image_url']?.toString() ?? '';
        }
      }
      enriched.add(base);
    }
    return enriched;
  }

  Future<void> addToCart(String obraId) async {
    await _dio.post(ApiConstants.cartItems, data: {'artwork_id': obraId});
  }

  Future<void> removeFromCart(String obraId) async {
    await _dio.delete(
      ApiConstants.cartItems,
      data: {'artwork_id': obraId},
    );
  }

  Future<void> clearCart() async {
    final items = await getCart();
    for (final item in items) {
      final obraId = item['artwork']?.toString() ?? item['obra_id']?.toString();
      if (obraId != null && obraId.isNotEmpty) {
        try {
          await removeFromCart(obraId);
        } catch (_) {}
      }
    }
  }

  Future<List<dynamic>> getFavorites() async {
    final r = await _dio.get(ApiConstants.favorites);
    final List<dynamic> raw = r.data is List
        ? r.data as List
        : (r.data['results'] as List? ?? []);

    final enriched = <Map<String, dynamic>>[];
    for (final fav in raw) {
      final base = Map<String, dynamic>.from(fav as Map);
      final artworkId = base['artwork_id']?.toString() ?? '';
      if (artworkId.isNotEmpty) {
        final artwork = await _artworkDetail(artworkId);
        if (artwork != null) {
          final slug = artwork['artist_slug']?.toString() ?? '';
          base['artista_nombre'] =
              artwork['artista_nombre']?.toString() ?? _nameFromSlug(slug);
          base['status'] = artwork['status'];
          base['price'] = artwork['price'];
          base['main_image_url'] = artwork['main_image_url'];
          if ((base['title']?.toString() ?? '').isEmpty) {
            base['title'] = artwork['title'];
          }
        }
      }
      enriched.add(base);
    }
    return enriched;
  }

  Future<void> addFavorite(String obraId) async {
    try {
      await _dio.post(ApiConstants.favorites, data: {'artwork_id': obraId});
    } on DioException catch (e) {
      // 400 = restricción única: ya es favorito → idempotente, no lanzar
      if (e.response?.statusCode != 400) rethrow;
    }
  }

  Future<void> removeFavorite(String obraId) async {
    try {
      await _dio.delete(ApiConstants.favorites, data: {'artwork_id': obraId});
    } on DioException catch (e) {
      // 400 = no era favorito → idempotente, no lanzar
      if (e.response?.statusCode != 400) rethrow;
    }
  }

  Future<Map<String, dynamic>> createOrder() async {
    final r = await _dio.post(ApiConstants.checkout);
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> getOrders() async {
    final r = await _dio.get(ApiConstants.orders);
    return r.data is List
        ? r.data as List
        : (r.data['results'] as List? ?? []);
  }

  Future<Map<String, dynamic>> getOrderDetail(String id) async {
    try {
      final url = ApiConstants.orderDetail.replaceAll('{id}', id);
      final r = await _dio.get(url);
      return (r.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      // Si el endpoint individual no existe en el backend, filtramos la lista
      if (e.response?.statusCode == 404) {
        final orders = await getOrders();
        final order = orders.firstWhere(
          (o) => o['id']?.toString() == id || o['order_id']?.toString() == id,
          orElse: () => <String, dynamic>{},
        );
        if ((order as Map).isNotEmpty) return Map<String, dynamic>.from(order);
        return {'id': id, 'items': [], 'status': 'unknown', 'total_amount': 0};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiatePayment(String orderId) async {
    final r = await _dio.post(
      ApiConstants.initiatePayment,
      data: {'order_id': orderId},
    );
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    final orders = await getOrders();
    final order = orders.firstWhere(
      (o) => o['id']?.toString() == orderId,
      orElse: () => <String, dynamic>{},
    );
    final rawStatus =
        (order as Map)['status']?.toString().toUpperCase() ?? 'PENDIENTE';
    final normalizedStatus = switch (rawStatus) {
      'PAGADO' => 'completado',
      'CANCELADO' => 'fallido',
      'REEMBOLSADO' => 'reembolsado',
      _ => 'pendiente',
    };
    return {'status': normalizedStatus};
  }

  Future<List<dynamic>> getPurchaseHistory() async {
    return getOrders();
  }

  Future<List<dynamic>> getSalesHistory() async {
    final r = await _dio.get(ApiConstants.salesHistory);
    return r.data is List
        ? r.data as List
        : (r.data['results'] as List? ?? []);
  }
}
