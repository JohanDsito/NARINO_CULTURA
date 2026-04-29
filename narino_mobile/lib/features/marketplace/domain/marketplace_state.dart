import 'cart_item_model.dart';
import 'favorite_model.dart';
import 'order_model.dart';

enum MarketplaceStatus { initial, loading, success, error }

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

class FavoritesState {
  const FavoritesState({
    this.status = MarketplaceStatus.initial,
    this.favorites = const [],
    this.errorMessage,
  });

  final MarketplaceStatus status;
  final List<FavoriteModel> favorites;
  final String? errorMessage;

  FavoritesState copyWith({
    MarketplaceStatus? status,
    List<FavoriteModel>? favorites,
    String? errorMessage,
    bool clearError = false,
  }) =>
      FavoritesState(
        status: status ?? this.status,
        favorites: favorites ?? this.favorites,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  bool get isLoading => status == MarketplaceStatus.loading;
  bool get hasError => errorMessage != null;

  bool isFavorite(int obraId) => favorites.any((f) => f.obraId == obraId);

  int? getFavoriteId(int obraId) {
    try {
      return favorites.firstWhere((f) => f.obraId == obraId).id;
    } catch (_) {
      return null;
    }
  }
}

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
