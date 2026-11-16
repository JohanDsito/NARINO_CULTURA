import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../domain/artwork_model.dart';
import 'artwork_service.dart';

/// Repositorio de obras: centraliza acceso a catálogo, detalle, publicación,
/// edición, eliminación y favoritos.
class ArtworkRepository {
  final ArtworkService _service;

  ArtworkRepository({ArtworkService? service})
      : _service = service ?? ArtworkService();

  Future<({List<ArtworkModel> artworks, int total})> getCatalog({
    String? search,
    String? categoria,
    String? tecnica,
    double? precioMin,
    double? precioMax,
    String ordenarPor = 'fecha',
    int page = 1,
  }) async {
    try {
      final data = await _service.getCatalog(
        search: search,
        categoria: categoria,
        tecnica: tecnica,
        precioMin: precioMin,
        precioMax: precioMax,
        ordenarPor: ordenarPor,
        page: page,
      );

      final resultsRaw = data['results'];
      final results = (resultsRaw is List ? resultsRaw : const <dynamic>[])
          .map((e) => ArtworkModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final count = data['count'];
      return (artworks: results, total: count is int ? count : results.length);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  /// Obras a la venta para la Tienda (no toca los filtros del catálogo).
  Future<List<ArtworkModel>> getDisponibles() async {
    try {
      final data = await _service.getDisponibles();
      final raw = data['results'];
      return (raw is List ? raw : const <dynamic>[])
          .whereType<Map>()
          .map((e) => ArtworkModel.fromJson(e.cast<String, dynamic>()))
          .where((a) => a.precio != null)
          .toList();
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<ArtworkModel> getDetail(String id) async {
    try {
      final data = await _service.getArtworkDetail(id);
      return ArtworkModel.fromJson(data);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final list = await _service.getCategories();
      return list
          .whereType<Map>()
          .map((e) => CategoryModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  /// Todas las obras publicadas por el artista [slug].
  Future<List<ArtworkModel>> getByArtist(String slug) async {
    if (slug.isEmpty) return const [];
    try {
      final list = await _service.getByArtist(slug);
      return list.map(ArtworkModel.fromJson).toList();
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<ArtworkModel> publish(FormData formData) async {
    try {
      final data = await _service.publishArtwork(formData);
      return ArtworkModel.fromJson(data);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<ArtworkModel> update(String id, FormData formData) async {
    try {
      final data = await _service.updateArtwork(id, formData);
      return ArtworkModel.fromJson(data);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _service.deleteArtwork(id);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<({bool esFavorito, int cantidad})> toggleFavorite(String id) async {
    try {
      final data = await _service.toggleFavorite(id);
      return (
        esFavorito: data['es_favorito'] as bool? ?? false,
        cantidad: data['cantidad_favoritos'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  String _parseDioError(DioException e) =>
      ApiError.message(e, byStatus: const {404: 'Obra no encontrada.'});
}
