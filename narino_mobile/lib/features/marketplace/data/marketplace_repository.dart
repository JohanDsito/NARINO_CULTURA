import 'package:dio/dio.dart';

import '../domain/cart_item_model.dart';
import '../domain/favorite_model.dart';
import '../domain/order_model.dart';
import 'marketplace_service.dart';

/// Repositorio del marketplace: carrito, favoritos, órdenes e integración de pago.
class MarketplaceRepository {
  MarketplaceRepository({MarketplaceService? service})
      : _service = service ?? MarketplaceService();

  final MarketplaceService _service;

  Future<List<CartItemModel>> getCart() async {
    try {
      return (await _service.getCart()).map((e) => CartItemModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<CartItemModel> addToCart(String obraId) async {
    try {
      return CartItemModel.fromJson(await _service.addToCart(obraId));
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> removeFromCart(String id) async {
    try {
      await _service.removeFromCart(id);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> clearCart() async {
    try {
      await _service.clearCart();
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<List<FavoriteModel>> getFavorites() async {
    try {
      return (await _service.getFavorites())
          .map((e) => FavoriteModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<FavoriteModel> addFavorite(String obraId) async {
    try {
      return FavoriteModel.fromJson(await _service.addFavorite(obraId));
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> removeFavorite(String id) async {
    try {
      await _service.removeFavorite(id);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<OrderModel> createOrder() async {
    try {
      return OrderModel.fromJson(await _service.createOrder());
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<List<OrderModel>> getOrders() async {
    try {
      return (await _service.getOrders()).map((e) => OrderModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<OrderModel> getOrderDetail(String id) async {
    try {
      return OrderModel.fromJson(await _service.getOrderDetail(id));
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<String> initiatePayment(String orderId) async {
    try {
      return (await _service.initiatePayment(orderId))['payment_url'] as String;
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<String> getPaymentStatus(String orderId) async {
    try {
      return (await _service.getPaymentStatus(orderId))['estado'] as String;
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<List<OrderModel>> getPurchaseHistory() async {
    try {
      return (await _service.getPurchaseHistory())
          .map((e) => OrderModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<List<OrderModel>> getSalesHistory() async {
    try {
      return (await _service.getSalesHistory())
          .map((e) => OrderModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  String _err(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'No se pudo conectar al servidor.';
    }
    final s = e.response?.statusCode;
    final d = e.response?.data;
    if (s == 400) {
      if (d is Map && d.containsKey('detail')) return d['detail'].toString();
      return 'Esta obra no está disponible.';
    }
    if (s == 403) return 'No tienes permiso para esta acción.';
    if (s == 404) return 'Elemento no encontrado.';
    return 'Error inesperado. Intenta de nuevo.';
  }
}
