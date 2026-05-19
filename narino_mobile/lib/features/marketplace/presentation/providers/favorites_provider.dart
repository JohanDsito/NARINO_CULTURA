import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/marketplace_repository.dart';
import '../../domain/marketplace_state.dart';
import 'cart_provider.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>(
  (ref) => FavoritesNotifier(ref.read(marketplaceRepositoryProvider)),
);

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier(this._repo) : super(const FavoritesState());

  final MarketplaceRepository _repo;

  Future<void> loadFavorites() async {
    state =
        state.copyWith(status: MarketplaceStatus.loading, clearError: true);
    try {
      state = state.copyWith(
        status: MarketplaceStatus.success,
        favorites: await _repo.getFavorites(),
      );
    } catch (e) {
      state = state.copyWith(
        status: MarketplaceStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> toggleFavorite(String obraId) async {
    final isFav = state.getFavoriteId(obraId) != null;
    if (isFav) {
      try {
        await _repo.removeFavorite(obraId);
        state = state.copyWith(
          favorites:
              state.favorites.where((f) => f.obraId != obraId).toList(),
        );
      } catch (e) {
        state = state.copyWith(errorMessage: e.toString());
      }
    } else {
      try {
        await _repo.addFavorite(obraId);
        await loadFavorites();
      } catch (e) {
        state = state.copyWith(errorMessage: e.toString());
      }
    }
  }
}
