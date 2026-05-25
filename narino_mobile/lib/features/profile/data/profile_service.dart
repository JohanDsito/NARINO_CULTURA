import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class ProfileService {
  ProfileService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// True si el string parece un slug (no un UUID).
  bool _looksLikeSlug(String? s) {
    if (s == null || s.isEmpty) return false;
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return !uuid.hasMatch(s);
  }

  /// Busca el perfil del artista en la lista paginada y devuelve su slug.
  Future<String?> _fetchArtistSlug(String? userId) async {
    if (userId == null || userId.isEmpty) return null;
    String? pageUrl = '${ApiConstants.artists}?page_size=100';
    while (pageUrl != null) {
      final res = await _dio.get(pageUrl);
      final List<dynamic> items;
      String? next;
      if (res.data is Map) {
        final data = res.data as Map;
        final raw = data['results'];
        items = raw is List ? raw : [];
        final n = data['next']?.toString();
        next = (n != null && n.isNotEmpty) ? n : null;
      } else if (res.data is List) {
        items = res.data as List;
        next = null;
      } else {
        break;
      }
      for (final a in items) {
        if (a is Map && a['user_id']?.toString() == userId) {
          return a['slug']?.toString();
        }
      }
      pageUrl = next;
    }
    return null;
  }

  /// Busca el mapa completo del artista en la lista paginada.
  Future<Map<String, dynamic>?> _fetchArtistData(String? userId) async {
    if (userId == null || userId.isEmpty) return null;
    String? pageUrl = '${ApiConstants.artists}?page_size=100';
    while (pageUrl != null) {
      final res = await _dio.get(pageUrl);
      final List<dynamic> items;
      String? next;
      if (res.data is Map) {
        final data = res.data as Map;
        final raw = data['results'];
        items = raw is List ? raw : [];
        final n = data['next']?.toString();
        next = (n != null && n.isNotEmpty) ? n : null;
      } else if (res.data is List) {
        items = res.data as List;
        next = null;
      } else {
        break;
      }
      for (final a in items) {
        if (a is Map && a['user_id']?.toString() == userId) {
          return Map<String, dynamic>.from(a);
        }
      }
      pageUrl = next;
    }
    return null;
  }

  // ─── API pública ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMyProfile() async {
    final userResponse = await _dio.get(ApiConstants.myProfile);
    final userData = Map<String, dynamic>.from(userResponse.data as Map);

    if ((userData['role'] as String?)?.toLowerCase() == 'artista') {
      try {
        final userId = userData['id']?.toString();
        final artistData = await _fetchArtistData(userId);
        if (artistData != null) {
          artistData['avatar_url'] ??= userData['avatar_url'];
          artistData['is_verified'] = userData['is_verified'];
          return artistData;
        }
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
    // ─── 1. Obtener userId del usuario actual ─────────────────────────────────
    final userResponse = await _dio.get(ApiConstants.myProfile);
    final userData = Map<String, dynamic>.from(userResponse.data as Map);
    final userId = userData['id']?.toString();

    // ─── 2. PATCH usuario ─────────────────────────────────────────────────────
    final userUpdates = <String, dynamic>{};
    if (nombreArtistico != null && nombreArtistico.isNotEmpty) {
      userUpdates['first_name'] = nombreArtistico;
    }
    if (userUpdates.isNotEmpty) {
      await _dio.patch(ApiConstants.myProfile, data: userUpdates);
    }

    // ─── 3. Actualizar perfil artístico (solo ARTISTAs) ───────────────────────
    if ((userData['role'] as String?)?.toLowerCase() == 'artista') {
      final artistUpdates = <String, dynamic>{};
      if (nombreArtistico != null) artistUpdates['artistic_name'] = nombreArtistico;
      if (disciplina != null) artistUpdates['discipline'] = disciplina;
      if (biografia != null) artistUpdates['bio'] = biografia;
      if (redesSociales != null) {
        String toUrl(String? v) => v?.trim() ?? '';
        artistUpdates['instagram_url'] = toUrl(redesSociales['instagram']);
        artistUpdates['facebook_url'] = toUrl(redesSociales['facebook']);
        artistUpdates['tiktok_url'] = toUrl(redesSociales['tiktok']);
        final website = toUrl(redesSociales['website']);
        if (website.isNotEmpty) artistUpdates['website_url'] = website;
      }

      if (artistUpdates.isNotEmpty) {
        // Resolver slug: usar el passado si es un slug real, sino buscar en lista
        String? slug = _looksLikeSlug(artistId) ? artistId : null;
        slug ??= await _fetchArtistSlug(userId);

        if (slug != null && slug.isNotEmpty) {
          await _dio.patch(
            ApiConstants.artistDetail.replaceAll('{id}', slug),
            data: artistUpdates,
            options: Options(contentType: 'application/json'),
          );
        } else {
          // El perfil de artista no existe: crear primero
          final artistName = (nombreArtistico?.isNotEmpty == true)
              ? nombreArtistico!
              : userData['first_name']?.toString() ?? 'Artista';
          final createData = <String, dynamic>{
            'artistic_name': artistName,
            ...artistUpdates,
          };
          await _dio.post(
            ApiConstants.artists,
            data: createData,
            options: Options(contentType: 'application/json'),
          );
        }
      }
    }

    // ─── 4. Refrescar y devolver datos actualizados ───────────────────────────
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
