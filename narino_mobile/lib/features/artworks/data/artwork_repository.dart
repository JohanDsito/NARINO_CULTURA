import 'package:dio/dio.dart';

import '../domain/artwork_model.dart';
import 'artwork_service.dart';

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

  Future<ArtworkModel> getDetail(int id) async {
    try {
      final data = await _service.getArtworkDetail(id);
      return ArtworkModel.fromJson(data);
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

  Future<ArtworkModel> update(int id, FormData formData) async {
    try {
      final data = await _service.updateArtwork(id, formData);
      return ArtworkModel.fromJson(data);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _service.deleteArtwork(id);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<({bool esFavorito, int cantidad})> toggleFavorite(int id) async {
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

  String _parseDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar al servidor.';
    }

    final code = e.response?.statusCode;
    final body = e.response?.data;

    if (code == 401) return 'Tu sesión expiró. Inicia sesión nuevamente.';
    if (code == 403) return 'No tienes permiso para realizar esta acción.';
    if (code == 404) return 'Obra no encontrada.';

    final extracted = _extractMessage(body);
    if (extracted != null && extracted.isNotEmpty) return extracted;

    return 'Error inesperado. Intenta de nuevo.';
  }

  String? _extractMessage(Object? data) {
    if (data is Map) {
      final detail = data['detail']?.toString();
      if (detail != null && detail.isNotEmpty) return detail;

      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          final msg = value.first?.toString();
          if (msg != null && msg.isNotEmpty) return msg;
        }
      }
    }

    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
