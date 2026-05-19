import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/marketplace_repository.dart';
import '../../domain/marketplace_state.dart';

final marketplaceRepositoryProvider =
    Provider<MarketplaceRepository>((ref) => MarketplaceRepository());

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(ref.read(marketplaceRepositoryProvider)),
);

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this._repo) : super(const CartState());

  final MarketplaceRepository _repo;

  Future<void> loadCart() async {
    state = state.copyWith(status: MarketplaceStatus.loading, clearError: true);
    try {
      state = state.copyWith(
        status: MarketplaceStatus.success,
        items: await _repo.getCart(),
      );
    } catch (e) {
      state = state.copyWith(
        status: MarketplaceStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> addToCart(String obraId) async {
    try {
      final item = await _repo.addToCart(obraId);
      state = state.copyWith(items: [...state.items, item]);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> removeFromCart(String id) async {
    try {
      await _repo.removeFromCart(id);
      state = state.copyWith(items: state.items.where((i) => i.id != id).toList());
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> clearCart() async {
    try {
      await _repo.clearCart();
      state = state.copyWith(items: []);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}
