import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/marketplace_repository.dart';
import '../../domain/favorite_model.dart';
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

  /// Marca o quita la obra de favoritos.
  ///
  /// El corazón cambia de inmediato (optimista) y vuelve atrás si el servidor
  /// falla, dejando el motivo en [FavoritesState.actionError]. Mientras una
  /// obra espera respuesta, otro toque sobre ella se ignora: antes cinco
  /// toques rápidos lanzaban cinco peticiones y recargas que se pisaban.
  ///
  /// [favorito] son los datos de la obra para mostrarla en Favoritos sin
  /// volver a pedir toda la lista; si no llega, se recarga la lista.
  Future<void> toggleFavorite(String obraId, {FavoriteModel? favorito}) async {
    if (state.isPending(obraId)) return;
    if (state.status == MarketplaceStatus.initial) {
      await loadFavorites();
      if (state.isPending(obraId)) return;
    }

    final add = !state.isFavorite(obraId);
    state = state.copyWith(
      pending: {...state.pending, obraId: add},
      clearActionError: true,
    );

    try {
      if (add) {
        await _repo.addFavorite(obraId);
      } else {
        await _repo.removeFavorite(obraId);
      }
      _settle(obraId);
      if (add) {
        if (favorito != null) {
          state = state.copyWith(favorites: [favorito, ...state.favorites]);
        } else {
          await loadFavorites();
        }
      } else {
        state = state.copyWith(
          favorites: state.favorites.where((f) => f.obraId != obraId).toList(),
        );
      }
    } catch (e) {
      _settle(obraId);
      state = state.copyWith(
        actionError: add
            ? 'No se pudo agregar a favoritos. $e'
            : 'No se pudo quitar de favoritos. $e',
      );
    }
  }

  /// El aviso de error ya se mostró.
  void clearActionError() => state = state.copyWith(clearActionError: true);

  void _settle(String obraId) {
    state = state.copyWith(pending: {...state.pending}..remove(obraId));
  }
}
