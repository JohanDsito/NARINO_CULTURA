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

    if (userData['role'] == 'ARTISTA') {
      try {
        final artistsResponse = await _dio.get(ApiConstants.artists);
        final artistsData = artistsResponse.data;
        List<dynamic> artists;
        if (artistsData is List) {
          artists = artistsData;
        } else if (artistsData is Map) {
          artists = (artistsData['results'] as List?) ?? [];
        } else {
          artists = [];
        }
        final userId = userData['id']?.toString();
        final Map? myArtist = artists.firstWhere(
          (a) => a['user_id']?.toString() == userId,
          orElse: () => null,
        ) as Map?;
        if (myArtist != null) {
          final merged = Map<String, dynamic>.from(myArtist);
          merged['avatar_url'] ??= userData['avatar_url'];
          merged['is_verified'] = userData['is_verified'];
          return merged;
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
  }) async {
    final userUpdates = <String, dynamic>{};
    if (nombreArtistico != null) userUpdates['first_name'] = nombreArtistico;
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

    final artistUpdates = <String, dynamic>{};
    if (nombreArtistico != null) artistUpdates['artistic_name'] = nombreArtistico;
    if (disciplina != null) artistUpdates['discipline'] = disciplina;
    if (biografia != null) artistUpdates['bio'] = biografia;
    if (redesSociales != null) {
      final instagram = redesSociales['instagram'];
      final website = redesSociales['website'];
      final facebook = redesSociales['facebook'];
      final tiktok = redesSociales['tiktok'];
      if (instagram != null) artistUpdates['instagram_url'] = instagram;
      if (website != null) artistUpdates['website_url'] = website;
      if (facebook != null) artistUpdates['facebook_url'] = facebook;
      if (tiktok != null) artistUpdates['tiktok_url'] = tiktok;
    }

    if (artistUpdates.isNotEmpty) {
      try {
        final userResponse = await _dio.get(ApiConstants.myProfile);
        final userId = (userResponse.data as Map)['id']?.toString();
        final artistsResponse = await _dio.get(ApiConstants.artists);
        final artistsData = artistsResponse.data;
        List<dynamic> artists;
        if (artistsData is List) {
          artists = artistsData;
        } else if (artistsData is Map) {
          artists = (artistsData['results'] as List?) ?? [];
        } else {
          artists = [];
        }
        final Map? myArtist = artists.firstWhere(
          (a) => a['user_id']?.toString() == userId,
          orElse: () => null,
        ) as Map?;
        if (myArtist != null) {
          final slug = myArtist['slug']?.toString() ?? '';
          if (slug.isNotEmpty) {
            final url = ApiConstants.profileById.replaceFirst('{id}', slug);
            await _dio.patch(url, data: artistUpdates);
          }
        }
      } catch (_) {}
    }

    return getMyProfile();
  }

  Future<Map<String, dynamic>> getProfileById(String id) async {
    final url = ApiConstants.profileById.replaceAll('{id}', id);
    final response = await _dio.get(url);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPortfolio(String profileId) async {
    return const [];
  }

  Future<Map<String, dynamic>> addPortfolioItem({
    required String profileId,
    required File file,
    required String tipo,
    String? titulo,
    String? descripcion,
  }) async {
    return const {};
  }

  Future<Map<String, dynamic>> updatePortfolioItem(
    String profileId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    return const {};
  }

  Future<void> deletePortfolioItem(String profileId, String itemId) async {
    return;
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
    return const [];
  }
}
