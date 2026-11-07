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

  /// Obras propias del artista autenticado (`?mine=true`): devuelve el total
  /// y, si hay al menos una, el slug del artista. Una sola petición.
  Future<({int count, String? slug})> _myArtworksSummary() async {
    final res = await _dio.get(
      ApiConstants.artworks,
      queryParameters: {'mine': 'true', 'page_size': 1},
    );
    final data = res.data;
    if (data is! Map) return (count: 0, slug: null);
    final results = data['results'] as List? ?? const [];
    final count = data['count'] is int ? data['count'] as int : results.length;
    final slug = results.isNotEmpty && results.first is Map
        ? (results.first as Map)['artist_slug']?.toString()
        : null;
    return (count: count, slug: slug);
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

  // ─── API pública ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMyProfile() async {
    final userResponse = await _dio.get(ApiConstants.myProfile);
    final userData = Map<String, dynamic>.from(userResponse.data as Map);

    if ((userData['role'] as String?)?.toLowerCase() == 'artista') {
      try {
        // 1 petición: total de obras propias + slug (si tiene obras).
        final resumen = await _myArtworksSummary();
        // Sin obras no hay de dónde sacar el slug: se busca en la lista.
        final slug = resumen.slug ??
            await _fetchArtistSlug(userData['id']?.toString());
        if (slug != null && slug.isNotEmpty) {
          final detailRes = await _dio.get(
            ApiConstants.artistDetail.replaceAll('{id}', slug),
          );
          final artistData = Map<String, dynamic>.from(detailRes.data as Map);
          // El serializer del backend no trae artworks_count.
          artistData['artworks_count'] ??= resumen.count;
          artistData['avatar_url'] ??= userData['avatar_url'];
          artistData['is_verified'] ??= userData['is_verified'];
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
    String? ciudad,
  }) async {
    // ─── 1. Obtener userId del usuario actual ─────────────────────────────────
    final userResponse = await _dio.get(ApiConstants.myProfile);
    final userData = Map<String, dynamic>.from(userResponse.data as Map);
    final userId = userData['id']?.toString();

    // ─── 2. PATCH usuario (texto + avatar en multipart si hay foto nueva) ────
    if (foto != null) {
      final formData = FormData.fromMap({
        if (nombreArtistico != null && nombreArtistico.isNotEmpty)
          'first_name': nombreArtistico,
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
    } else if (nombreArtistico != null && nombreArtistico.isNotEmpty) {
      await _dio.patch(ApiConstants.myProfile, data: {'first_name': nombreArtistico});
    }

    // ─── 3. Actualizar perfil artístico (solo ARTISTAs) ───────────────────────
    if ((userData['role'] as String?)?.toLowerCase() == 'artista') {
      final artistUpdates = <String, dynamic>{};
      if (nombreArtistico != null) artistUpdates['artistic_name'] = nombreArtistico;
      if (disciplina != null) artistUpdates['discipline'] = disciplina;
      if (biografia != null) artistUpdates['bio'] = biografia;
      if (ciudad != null) artistUpdates['city'] = ciudad.trim();
      if (redesSociales != null) {
        String toUrl(String? v) => v?.trim() ?? '';
        artistUpdates['instagram_url'] = toUrl(redesSociales['instagram']);
        artistUpdates['facebook_url'] = toUrl(redesSociales['facebook']);
        artistUpdates['tiktok_url'] = toUrl(redesSociales['tiktok']);
        // Se envía aunque esté vacío para poder quitar el sitio web.
        artistUpdates['website_url'] = toUrl(redesSociales['website']);
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

  /// Artistas y músicos que sigue el usuario. Cada elemento lleva `_tipo`
  /// (`artista` | `musico`) para saber a qué pantalla navegar.
  Future<List<dynamic>> getMyFollowing() async {
    Future<List<dynamic>> fetch(String url, String tipo) async {
      try {
        final r = await _dio.get(url);
        final raw = r.data is List
            ? r.data as List
            : (r.data is Map ? (r.data['results'] as List?) ?? [] : []);
        return raw
            .whereType<Map>()
            .map((e) => {...e.cast<String, dynamic>(), '_tipo': tipo})
            .toList();
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return [];
        rethrow;
      }
    }

    final results = await Future.wait([
      fetch(ApiConstants.artistsFollowing, 'artista'),
      fetch(ApiConstants.musiciansFollowing, 'musico'),
    ]);
    return [...results[0], ...results[1]];
  }
}
