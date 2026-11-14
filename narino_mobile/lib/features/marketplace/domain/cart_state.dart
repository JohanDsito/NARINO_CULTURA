import 'cart_item_model.dart';
import 'marketplace_status.dart';

class CartState {
  const CartState({
    this.status = MarketplaceStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final MarketplaceStatus status;
  final List<CartItemModel> items;
  final String? errorMessage;

  CartState copyWith({
    MarketplaceStatus? status,
    List<CartItemModel>? items,
    String? errorMessage,
    bool clearError = false,
  }) =>
      CartState(
        status: status ?? this.status,
        items: items ?? this.items,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  bool get isLoading => status == MarketplaceStatus.loading;
  bool get hasError => errorMessage != null;
  int get itemCount => items.length;

  double get total => items.fold(0, (s, i) => s + i.precio);

  String get totalFormateado {
    final n = total
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }
}
