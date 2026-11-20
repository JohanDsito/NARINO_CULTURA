import 'favorite_model.dart';
import 'marketplace_status.dart';

class FavoritesState {
  const FavoritesState({
    this.status = MarketplaceStatus.initial,
    this.favorites = const [],
    this.pending = const {},
    this.errorMessage,
    this.actionError,
  });

  final MarketplaceStatus status;
  final List<FavoriteModel> favorites;

  /// Corazones tocados que esperan respuesta del servidor: obra → estado al
  /// que va. La interfaz ya los muestra así (optimista) y no acepta otro toque
  /// sobre la misma obra hasta que responda (MO-LOAD-02).
  final Map<String, bool> pending;

  /// Error al cargar la lista (la pantalla muestra "Reintentar").
  final String? errorMessage;

  /// Error al marcar o quitar un favorito; se avisa con un SnackBar y se borra.
  final String? actionError;

  FavoritesState copyWith({
    MarketplaceStatus? status,
    List<FavoriteModel>? favorites,
    Map<String, bool>? pending,
    String? errorMessage,
    bool clearError = false,
    String? actionError,
    bool clearActionError = false,
  }) =>
      FavoritesState(
        status: status ?? this.status,
        favorites: favorites ?? this.favorites,
        pending: pending ?? this.pending,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        actionError:
            clearActionError ? null : (actionError ?? this.actionError),
      );

  bool get isLoading => status == MarketplaceStatus.loading;
  bool get hasError => status == MarketplaceStatus.error;

  /// Si la obra está en favoritos, contando los toques que aún no responden.
  bool isFavorite(String obraId) =>
      pending[obraId] ?? favorites.any((f) => f.obraId == obraId);

  bool isPending(String obraId) => pending.containsKey(obraId);
}
