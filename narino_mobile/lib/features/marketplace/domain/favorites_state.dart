import 'favorite_model.dart';
import 'marketplace_status.dart';

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

  bool isFavorite(String obraId) => favorites.any((f) => f.obraId == obraId);

  String? getFavoriteId(String obraId) {
    try {
      return favorites.firstWhere((f) => f.obraId == obraId).id;
    } catch (_) {
      return null;
    }
  }
}
