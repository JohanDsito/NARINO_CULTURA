import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/artwork_repository.dart';
import '../../domain/artwork_model.dart';
import '../../domain/artwork_state.dart';

final artworkRepositoryProvider = Provider<ArtworkRepository>((ref) {
  return ArtworkRepository();
});

final artworkProvider = StateNotifierProvider<ArtworkNotifier, ArtworkState>(
  (ref) => ArtworkNotifier(ref.read(artworkRepositoryProvider)),
);

final artworkDetailProvider =
    FutureProvider.family.autoDispose<ArtworkModel, String>((ref, id) async {
  return ref.read(artworkRepositoryProvider).getDetail(id);
});

class ArtworkNotifier extends StateNotifier<ArtworkState> {
  ArtworkNotifier(this._repo) : super(const ArtworkState());

  final ArtworkRepository _repo;

  Future<void> loadCatalog({bool resetFiltros = false}) async {
    if (resetFiltros) {
      state = const ArtworkState(status: ArtworkStatus.loading);
    } else {
      state = state.copyWith(status: ArtworkStatus.loading, clearError: true);
    }

    try {
      final result = await _repo.getCatalog(
        search: state.busqueda.isEmpty ? null : _normalize(state.busqueda),
        categoria: state.categoriaFiltro,
        tecnica: state.tecnicaFiltro,
        precioMin: state.precioMinFiltro,
        precioMax: state.precioMaxFiltro,
        ordenarPor: state.ordenarPor,
      );

      var list = result.artworks;
      if (state.soloFavoritos) {
        list = list.where((a) => a.esFavorito).toList();
      }

      state = state.copyWith(
        status: ArtworkStatus.loaded,
        artworks: list,
        totalResultados: result.total,
      );
    } catch (e) {
      state = state.copyWith(
        status: ArtworkStatus.error,
        errorMessage: e.toString(),
      );
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
    state = state.copyWith(precioMinFiltro: min, precioMaxFiltro: max);
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

  void limpiarFiltros() {
    state = const ArtworkState();
    loadCatalog();
  }

  Future<void> toggleFavorite(String artworkId) async {
    final idx = state.artworks.indexWhere((a) => a.id == artworkId);
    if (idx == -1) return;

    final before = state.artworks[idx];
    final optimistic = before.copyWith(
      esFavorito: !before.esFavorito,
      cantidadFavoritos: before.esFavorito
          ? (before.cantidadFavoritos - 1).clamp(0, 1 << 30)
          : before.cantidadFavoritos + 1,
    );

    final updated = [...state.artworks];
    updated[idx] = optimistic;
    state = state.copyWith(artworks: updated);

    try {
      final result = await _repo.toggleFavorite(artworkId);
      final synced = before.copyWith(
        esFavorito: result.esFavorito,
        cantidadFavoritos: optimistic.cantidadFavoritos,
      );

      final latest = [...state.artworks];
      final currentIdx = latest.indexWhere((a) => a.id == artworkId);
      if (currentIdx != -1) {
        latest[currentIdx] = synced;
        state = state.copyWith(
          artworks: state.soloFavoritos
              ? latest.where((a) => a.esFavorito).toList()
              : latest,
        );
      }
    } catch (_) {
      final revert = [...state.artworks];
      final currentIdx = revert.indexWhere((a) => a.id == artworkId);
      if (currentIdx != -1) {
        revert[currentIdx] = before;
        state = state.copyWith(artworks: revert);
      }
    }
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
