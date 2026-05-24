import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class ProfileService {
  ProfileService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<Map<String, dynamic>> getMyProfile() async {
    final userResponse = await _dio.get(ApiConstants.myProfile);
    final userData = Map<String, dynamic>.from(userResponse.data as Map);

    if ((userData['role'] as String?)?.toLowerCase() == 'artista') {
      try {
        final artistResponse = await _dio.get(ApiConstants.artistMe);
        final artistData = Map<String, dynamic>.from(artistResponse.data as Map);
        artistData['avatar_url'] ??= userData['avatar_url'];
        artistData['is_verified'] = userData['is_verified'];
        return artistData;
      } catch (_) {}
    }

    return userData;
  }

  Future<Map<String, dynamic>> updateMyProfile({
    String? nombreArtistico,
    String? disciplina,
    String? biografia,
    File? foto,
    Map<String, String>? redesSociales,
    String? artistId,
  }) async {
    // ─── 1. PATCH registro de usuario (nombre + avatar) ───────────────────
    final userUpdates = <String, dynamic>{};
    if (nombreArtistico != null && nombreArtistico.isNotEmpty) {
      userUpdates['first_name'] = nombreArtistico;
    }
    if (foto != null) {
      final formData = FormData.fromMap({
        ...userUpdates,
        'avatar': await MultipartFile.fromFile(
          foto.path,
          filename: foto.path.split(Platform.pathSeparator).last,
        ),
      });
      await _dio.patch(
        ApiConstants.myProfile,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } else if (userUpdates.isNotEmpty) {
      await _dio.patch(ApiConstants.myProfile, data: userUpdates);
    }

    // ─── 2. PATCH perfil de artista vía /me/ (sin depender de slug/ID) ───
    final artistUpdates = <String, dynamic>{};
    if (nombreArtistico != null) artistUpdates['artistic_name'] = nombreArtistico;
    if (disciplina != null) artistUpdates['discipline'] = disciplina;
    if (biografia != null) artistUpdates['bio'] = biografia;
    if (redesSociales != null) {
      // URLField(blank=True) en Django acepta '' para limpiar el campo.
      String toUrl(String? v) => v?.trim() ?? '';
      artistUpdates['instagram_url'] = toUrl(redesSociales['instagram']);
      artistUpdates['facebook_url'] = toUrl(redesSociales['facebook']);
      artistUpdates['tiktok_url'] = toUrl(redesSociales['tiktok']);
      final website = toUrl(redesSociales['website']);
      if (website.isNotEmpty) artistUpdates['website_url'] = website;
    }

    if (artistUpdates.isNotEmpty) {
      await _dio.patch(
        ApiConstants.artistMe,
        data: artistUpdates,
        options: Options(contentType: 'application/json'),
      );
    }

    // ─── 3. Refrescar desde /me/ para devolver datos actualizados ─────────
    return getMyProfile();
  }

  Future<Map<String, dynamic>> getProfileById(String id) async {
    final url = ApiConstants.profileById.replaceAll('{id}', id);
    final response = await _dio.get(url);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPortfolio(String profileId) async {
    try {
      final url = ApiConstants.artistPortfolio.replaceAll('{id}', profileId);
      final r = await _dio.get(url);
      if (r.data is List) return r.data as List;
      if (r.data is Map) return (r.data['results'] as List?) ?? [];
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addPortfolioItem({
    required String profileId,
    required File file,
    required String tipo,
    String? titulo,
    String? descripcion,
  }) async {
    final url = ApiConstants.artistPortfolio.replaceAll('{id}', profileId);
    final formData = FormData.fromMap({
      'media': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
      'tipo': tipo,
      if (titulo != null) 'titulo': titulo,
      if (descripcion != null) 'descripcion': descripcion,
    });
    final r = await _dio.post(
      url,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updatePortfolioItem(
    String profileId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    final url = ApiConstants.artistPortfolioItem
        .replaceAll('{id}', profileId)
        .replaceAll('{item_id}', itemId);
    final r = await _dio.patch(url, data: data);
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<void> deletePortfolioItem(String profileId, String itemId) async {
    final url = ApiConstants.artistPortfolioItem
        .replaceAll('{id}', profileId)
        .replaceAll('{item_id}', itemId);
    await _dio.delete(url);
  }

  Future<Map<String, dynamic>> followArtist(String profileId) async {
    final url = ApiConstants.artistFollow.replaceAll('{id}', profileId);
    final response = await _dio.post(url, data: {});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unfollowArtist(String profileId) async {
    final url = ApiConstants.artistFollow.replaceAll('{id}', profileId);
    final response = await _dio.post(url, data: {});
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyFollowing() async {
    try {
      final r = await _dio.get(ApiConstants.myFollowing);
      if (r.data is List) return r.data as List;
      if (r.data is Map) return (r.data['results'] as List?) ?? [];
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }
}
