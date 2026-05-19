import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class MarketplaceService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<dynamic>> getCart() async {
    final r = await _dio.get(ApiConstants.cart);
    final data = r.data;
    if (data is List) return data;
    if (data is Map) return (data['items'] as List? ?? data['results'] as List? ?? []);
    return [];
  }

  Future<Map<String, dynamic>> addToCart(String obraId) async {
    final r = await _dio.post(ApiConstants.cart, data: {'obra_id': obraId});
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<void> removeFromCart(String id) async {
    await _dio.delete(ApiConstants.cartItem.replaceFirst('{id}', id));
  }

  Future<void> clearCart() async {
    await _dio.delete(ApiConstants.cart);
  }

  Future<List<dynamic>> getFavorites() async {
    final r = await _dio.get(ApiConstants.favorites);
    return r.data is List ? r.data : (r.data['results'] ?? []);
  }

  Future<Map<String, dynamic>> addFavorite(String obraId) async {
    final r =
        await _dio.post(ApiConstants.favorites, data: {'obra_id': obraId});
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<void> removeFavorite(String id) async {
    await _dio.delete(
      ApiConstants.favoriteItem.replaceFirst('{id}', id),
    );
  }

  Future<Map<String, dynamic>> createOrder() async {
    final r = await _dio.post(ApiConstants.orders);
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> getOrders() async {
    final r = await _dio.get(ApiConstants.orders);
    return r.data is List ? r.data : (r.data['results'] ?? []);
  }

  Future<Map<String, dynamic>> getOrderDetail(String id) async {
    final r = await _dio.get(
      ApiConstants.orderDetail.replaceFirst('{id}', id),
    );
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> initiatePayment(String orderId) async {
    final r = await _dio.post(
      ApiConstants.initiatePayment,
      data: {'order_id': orderId},
    );
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    final r = await _dio.get(
      ApiConstants.paymentStatus.replaceFirst('{id}', orderId),
    );
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> getPurchaseHistory() async {
    final r = await _dio.get(ApiConstants.purchaseHistory);
    return r.data is List ? r.data : (r.data['results'] ?? []);
  }

  Future<List<dynamic>> getSalesHistory() async {
    final r = await _dio.get(ApiConstants.salesHistory);
    return r.data is List ? r.data : (r.data['results'] ?? []);
  }
}
