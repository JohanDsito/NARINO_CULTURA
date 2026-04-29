import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class ProfileService {
  ProfileService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _dio.get(ApiConstants.myProfile);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMyProfile({
    String? nombreArtistico,
    String? disciplina,
    String? biografia,
    File? foto,
    Map<String, String>? redesSociales,
  }) async {
    final formData = FormData.fromMap({
      if (nombreArtistico != null) 'nombre_artistico': nombreArtistico,
      if (disciplina != null) 'disciplina': disciplina,
      if (biografia != null) 'biografia': biografia,
      if (redesSociales != null) 'redes_sociales': redesSociales,
      if (foto != null)
        'foto': await MultipartFile.fromFile(
          foto.path,
          filename: foto.path.split(Platform.pathSeparator).last,
        ),
    });

    final response = await _dio.patch(
      ApiConstants.myProfile,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProfileById(int id) async {
    final url = ApiConstants.profileById.replaceAll('{id}', '$id');
    final response = await _dio.get(url);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPortfolio(int profileId) async {
    final url = ApiConstants.portfolioItems.replaceAll('{id}', '$profileId');
    final response = await _dio.get(url);
    final data = response.data;
    if (data is List) return data;
    if (data is Map) return (data['results'] as List? ?? const []);
    return const [];
  }

  Future<Map<String, dynamic>> addPortfolioItem({
    required int profileId,
    required File file,
    required String tipo,
    String? titulo,
    String? descripcion,
  }) async {
    final formData = FormData.fromMap({
      'tipo': tipo,
      if (titulo != null) 'titulo': titulo,
      if (descripcion != null) 'descripcion': descripcion,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });

    final url = ApiConstants.portfolioItems.replaceAll('{id}', '$profileId');
    final response = await _dio.post(
      url,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePortfolioItem(
    int profileId,
    int itemId,
    Map<String, dynamic> data,
  ) async {
    final url = ApiConstants.portfolioItem
        .replaceAll('{id}', '$profileId')
        .replaceAll('{item_id}', '$itemId');
    final response = await _dio.patch(url, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deletePortfolioItem(int profileId, int itemId) async {
    final url = ApiConstants.portfolioItem
        .replaceAll('{id}', '$profileId')
        .replaceAll('{item_id}', '$itemId');
    await _dio.delete(url);
  }

  Future<Map<String, dynamic>> followArtist(int profileId) async {
    final url = ApiConstants.followArtist.replaceAll('{id}', '$profileId');
    final response = await _dio.post(url, data: {});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unfollowArtist(int profileId) async {
    final url = ApiConstants.unfollowArtist.replaceAll('{id}', '$profileId');
    final response = await _dio.post(url, data: {});
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyFollowing() async {
    final response = await _dio.get(ApiConstants.myFollowing);
    final data = response.data;
    if (data is List) return data;
    if (data is Map) return (data['results'] as List? ?? const []);
    return const [];
  }
}
