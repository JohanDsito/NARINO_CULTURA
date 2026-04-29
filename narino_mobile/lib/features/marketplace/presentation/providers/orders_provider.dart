import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/marketplace_repository.dart';
import '../../domain/marketplace_state.dart';
import '../../domain/order_model.dart';
import 'cart_provider.dart';

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>(
  (ref) => OrdersNotifier(ref.read(marketplaceRepositoryProvider)),
);

final orderDetailProvider = FutureProvider.family<OrderModel, int>(
  (ref, id) async => ref.read(marketplaceRepositoryProvider).getOrderDetail(id),
);

class OrdersNotifier extends StateNotifier<OrdersState> {
  OrdersNotifier(this._repo) : super(const OrdersState());

  final MarketplaceRepository _repo;
  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(status: MarketplaceStatus.loading, clearError: true);
    try {
      state = state.copyWith(
        status: MarketplaceStatus.success,
        orders: await _repo.getOrders(),
      );
    } catch (e) {
      state = state.copyWith(
        status: MarketplaceStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<OrderModel?> createOrder() async {
    try {
      final order = await _repo.createOrder();
      state = state.copyWith(orders: [order, ...state.orders]);
      return order;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<String?> initiatePayment(int orderId) async {
    try {
      return await _repo.initiatePayment(orderId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  void startPaymentPolling({
    required int orderId,
    required void Function(String estado) onEstado,
    Duration interval = const Duration(seconds: 5),
  }) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) async {
      try {
        final estado = await _repo.getPaymentStatus(orderId);
        onEstado(estado);
      } catch (_) {}
    });
  }

  void stopPaymentPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}
