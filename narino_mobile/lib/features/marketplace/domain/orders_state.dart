import 'marketplace_status.dart';
import 'order_model.dart';

class OrdersState {
  const OrdersState({
    this.status = MarketplaceStatus.initial,
    this.orders = const [],
    this.errorMessage,
  });

  final MarketplaceStatus status;
  final List<OrderModel> orders;
  final String? errorMessage;

  OrdersState copyWith({
    MarketplaceStatus? status,
    List<OrderModel>? orders,
    String? errorMessage,
    bool clearError = false,
  }) =>
      OrdersState(
        status: status ?? this.status,
        orders: orders ?? this.orders,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  bool get isLoading => status == MarketplaceStatus.loading;
  bool get hasError => errorMessage != null;
}
