import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/artwork_repository.dart';
import '../../domain/artwork_model.dart';
import '../../domain/artwork_state.dart';

final artworkRepositoryProvider = Provider<ArtworkRepository>((ref) {
  return ArtworkRepository();
});

final categoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  return ref.read(artworkRepositoryProvider).getCategories();
});

final artworkProvider = StateNotifierProvider<ArtworkNotifier, ArtworkState>(
  (ref) => ArtworkNotifier(ref.read(artworkRepositoryProvider)),
);

final artworkDetailProvider =
    FutureProvider.family.autoDispose<ArtworkModel, String>((ref, id) async {
  return ref.read(artworkRepositoryProvider).getDetail(id);
});

/// Todas las obras publicadas de un artista, filtradas en el servidor.
final artistArtworksProvider =
    FutureProvider.family<List<ArtworkModel>, String>((ref, slug) async {
  try {
    return await ref.read(artworkRepositoryProvider).getByArtist(slug);
  } catch (_) {
    return const [];
  }
});

class ArtworkNotifier extends StateNotifier<ArtworkState> {
  ArtworkNotifier(this._repo) : super(const ArtworkState());

  final ArtworkRepository _repo;

  /// Identifica la última búsqueda: si llega tarde la respuesta de una
  /// anterior (p. ej. al escribir rápido), se descarta en vez de pisarla.
  int _request = 0;

  Future<({List<ArtworkModel> artworks, int total})> _fetch(int page) =>
      _repo.getCatalog(
        search: state.busqueda.isEmpty ? null : _normalize(state.busqueda),
        categoria: state.categoriaFiltro,
        tecnica: state.tecnicaFiltro,
        precioMin: state.precioMinFiltro,
        precioMax: state.precioMaxFiltro,
        ordenarPor: state.ordenarPor,
        page: page,
      );

  List<ArtworkModel> _visibles(List<ArtworkModel> list) =>
      state.soloFavoritos ? list.where((a) => a.esFavorito).toList() : list;

  /// Primera página con los filtros actuales.
  Future<void> loadCatalog({bool resetFiltros = false}) async {
    final id = ++_request;
    if (resetFiltros) {
      state = const ArtworkState(status: ArtworkStatus.loading);
    } else {
      state = state.copyWith(
        status: ArtworkStatus.loading,
        clearError: true,
        isLoadingMore: false,
        clearLoadMoreError: true,
      );
    }

    try {
      final result = await _fetch(1);
      if (id != _request) return;
      state = state.copyWith(
        status: ArtworkStatus.loaded,
        artworks: _visibles(result.artworks),
        totalResultados: result.total,
        page: 1,
        cargadas: result.artworks.length,
      );
    } catch (e) {
      if (id != _request) return;
      state = state.copyWith(
        status: ArtworkStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Siguiente página al acercarse al final de la lista (MO-LOAD-01). Antes
  /// solo se veía la primera página aunque el contador dijera el total.
  Future<void> loadMore() async {
    if (state.status != ArtworkStatus.loaded ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    final id = _request;
    final next = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);

    try {
      final result = await _fetch(next);
      if (id != _request) return; // cambiaron los filtros mientras tanto
      final vistas = state.artworks.map((a) => a.id).toSet();
      final nuevas = _visibles(result.artworks)
          .where((a) => !vistas.contains(a.id))
          .toList();
      state = state.copyWith(
        artworks: [...state.artworks, ...nuevas],
        page: next,
        // Una página vacía significa que no hay más, aunque el total diga otra cosa.
        cargadas: result.artworks.isEmpty
            ? result.total
            : state.cargadas + result.artworks.length,
        totalResultados: result.total,
        isLoadingMore: false,
      );
    } catch (e) {
      if (id != _request) return;
      state = state.copyWith(isLoadingMore: false, loadMoreError: e.toString());
    }
  }

  void setBusqueda(String texto) {
    state = state.copyWith(busqueda: texto);
    loadCatalog();
  }

  void setCategoria(String? categoria) {
    state = state.copyWith(
      categoriaFiltro: categoria,
      clearCategoriaFiltro: categoria == null,
    );
    loadCatalog();
  }

  void setTecnica(String? tecnica) {
    state = state.copyWith(
      tecnicaFiltro: tecnica,
      clearTecnicaFiltro: tecnica == null,
    );
    loadCatalog();
  }

  void setRangoPrecio(double? min, double? max) {
    // `clearPrecio` permite quitar el rango (antes `null` no lo borraba).
    state = state.copyWith(
        precioMinFiltro: min, precioMaxFiltro: max, clearPrecio: true);
    loadCatalog();
  }

  void setOrden(String orden) {
    state = state.copyWith(ordenarPor: orden);
    loadCatalog();
  }

  void setSoloFavoritos(bool value) {
    state = state.copyWith(soloFavoritos: value);
    loadCatalog();
  }

  /// Aplica todos los filtros del panel de una vez (una sola petición).
  void aplicarFiltros({
    String? categoria,
    String? tecnica,
    double? precioMin,
    double? precioMax,
    String orden = 'fecha',
  }) {
    state = state.copyWith(
      categoriaFiltro: categoria,
      clearCategoriaFiltro: categoria == null,
      tecnicaFiltro: tecnica,
      clearTecnicaFiltro: tecnica == null,
      precioMinFiltro: precioMin,
      precioMaxFiltro: precioMax,
      clearPrecio: true,
      ordenarPor: orden,
    );
    loadCatalog();
  }

  /// Quita los filtros del panel pero conserva la búsqueda escrita.
  void limpiarFiltrosPanel() => aplicarFiltros();

  void limpiarFiltros() {
    state = const ArtworkState();
    loadCatalog();
  }

  Future<bool> deleteArtwork(String artworkId) async {
    try {
      await _repo.delete(artworkId);
      state = state.copyWith(
        artworks: state.artworks.where((a) => a.id != artworkId).toList(),
        totalResultados: state.totalResultados - 1,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<ArtworkModel?> publish(FormData formData) async {
    try {
      final artwork = await _repo.publish(formData);
      state = state.copyWith(
        artworks: [artwork, ...state.artworks],
        totalResultados: state.totalResultados + 1,
      );
      return artwork;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<ArtworkModel?> update(String id, FormData formData) async {
    try {
      final updated = await _repo.update(id, formData);
      final updatedList =
          state.artworks.map((a) => a.id == id ? updated : a).toList();
      state = state.copyWith(artworks: updatedList);
      return updated;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }
}

String _normalize(String input) {
  const from = 'áàäâãåÁÀÄÂÃÅéèëêÉÈËÊíìïîÍÌÏÎóòöôõÓÒÖÔÕúùüûÚÙÜÛñÑ';
  const to = 'aaaaaaAAAAAAeeeeEEEEiiiiIIIIoooooOOOOOuuuuUUUUnN';

  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final idx = from.indexOf(ch);
    buffer.write(idx >= 0 ? to[idx] : ch);
  }
  return buffer.toString().toLowerCase();
}
