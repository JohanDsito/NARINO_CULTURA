import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class MarketplaceService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<dynamic>> getCart() async {
    final r = await _dio.get(ApiConstants.cart);
    final data = r.data;
    if (data is List) return data;
    if (data is Map) {
      return (data['items'] as List?) ??
          (data['results'] as List?) ??
          [];
    }
    return [];
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
    return r.data is List
        ? r.data as List
        : (r.data['results'] as List? ?? []);
  }

  Future<void> addFavorite(String obraId) async {
    await _dio.post(ApiConstants.favorites, data: {'artwork_id': obraId});
  }

  Future<void> removeFavorite(String obraId) async {
    await _dio.delete(
      ApiConstants.favorites,
      data: {'artwork_id': obraId},
    );
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
    final orders = await getOrders();
    final order = orders.firstWhere(
      (o) => o['id']?.toString() == id || o['order_id']?.toString() == id,
      orElse: () => <String, dynamic>{},
    );
    if ((order as Map).isNotEmpty) {
      return Map<String, dynamic>.from(order);
    }
    return {'id': id, 'items': [], 'status': 'unknown', 'total_amount': 0};
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
    return {'status': (order as Map)['status']?.toString() ?? 'unknown'};
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
