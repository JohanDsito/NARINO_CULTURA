import 'package:dio/dio.dart';

import '../domain/musician_model.dart';
import 'musician_service.dart';

class MusicianRepository {
  MusicianRepository({MusicianService? service})
      : _service = service ?? MusicianService();

  final MusicianService _service;

  Future<List<MusicianModel>> getMusicians({
    String? search,
    String? genre,
    String? city,
    String? aggregationType,
    int page = 1,
  }) async {
    try {
      final data = await _service.getMusicians(
        search: search,
        genre: genre,
        city: city,
        aggregationType: aggregationType,
        page: page,
      );
      final results = data['results'];
      if (results is List) {
        return results
            .whereType<Map>()
            .map((e) => MusicianModel.fromJson(e.cast<String, dynamic>()))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<MusicianModel> getMusicianDetail(String slug) async {
    try {
      final data = await _service.getMusicianDetail(slug);
      return MusicianModel.fromJson(data);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<bool> toggleFollow(String slug) async {
    try {
      return await _service.toggleFollow(slug);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<MusicalWorkModel> addWork(
    String slug,
    Map<String, dynamic> payload,
  ) async {
    try {
      final data = await _service.addWork(slug, payload);
      return MusicalWorkModel.fromJson(data);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<List<MusicalWorkModel>> getMusicianWorks(String slug) async {
    try {
      final list = await _service.getMusicianWorks(slug);
      return list
          .whereType<Map>()
          .map((e) => MusicalWorkModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<List<MusicianReviewModel>> getMusicianReviews(String slug) async {
    try {
      final list = await _service.getMusicianReviews(slug);
      return list
          .whereType<Map>()
          .map((e) => MusicianReviewModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<List<MusicGenreModel>> getGenres() async {
    try {
      final list = await _service.getGenres();
      return list
          .whereType<Map>()
          .map((e) => MusicGenreModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  /// Perfil de músico del usuario autenticado, o `null` si aún no tiene uno.
  Future<MusicianModel?> getMyProfile() async {
    try {
      final data = await _service.getMyProfile();
      return data == null ? null : MusicianModel.fromJson(data);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  /// Crea o actualiza el perfil de músico del usuario autenticado.
  Future<MusicianModel> saveMyProfile({
    required String artisticName,
    String? aggregationType,
    List<int>? genreIds,
    String? existingSlug,
  }) async {
    try {
      final data = await _service.saveMyProfile(
        artisticName: artisticName,
        aggregationType: aggregationType,
        genreIds: genreIds,
        existingSlug: existingSlug,
      );
      return MusicianModel.fromJson(data);
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
    if (code == 401) return 'Tu sesión expiró. Inicia sesión nuevamente.';
    if (code == 403) return 'No tienes permiso para realizar esta acción.';
    if (code == 404) return 'Músico no encontrado.';
    final extracted = _extractMessage(e.response?.data);
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
        if (value is String && value.isNotEmpty) return value;
      }
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
