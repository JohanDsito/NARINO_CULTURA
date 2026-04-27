import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class ArtworkService {
  Dio get _dio => ApiClient.instance.dio;

  Future<Map<String, dynamic>> getCatalog({
    String? search,
    String? categoria,
    String? tecnica,
    double? precioMin,
    double? precioMax,
    String ordenarPor = 'fecha',
    int page = 1,
  }) async {
    final queryParams = <String, dynamic>{
      'ordering': _mapOrden(ordenarPor),
      'page': page,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (categoria != null && categoria.isNotEmpty) {
      queryParams['categoria'] = categoria;
    }
    if (tecnica != null && tecnica.isNotEmpty) queryParams['tecnica'] = tecnica;
    if (precioMin != null) queryParams['precio_min'] = precioMin;
    if (precioMax != null) queryParams['precio_max'] = precioMax;

    final response = await _dio.get(
      ApiConstants.artworks,
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getArtworkDetail(int id) async {
    final url = ApiConstants.artworkDetail.replaceAll('{id}', '$id');
    final response = await _dio.get(url);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> publishArtwork(FormData formData) async {
    final response = await _dio.post(
      ApiConstants.artworks,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateArtwork(int id, FormData formData) async {
    final url = ApiConstants.artworkDetail.replaceAll('{id}', '$id');
    final response = await _dio.patch(
      url,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteArtwork(int id) async {
    final url = ApiConstants.artworkDetail.replaceAll('{id}', '$id');
    await _dio.delete(url);
  }

  Future<Map<String, dynamic>> toggleFavorite(int artworkId) async {
    final response = await _dio.post(
      '${ApiConstants.artworks}$artworkId/favorito/',
    );
    return response.data as Map<String, dynamic>;
  }

  String _mapOrden(String orden) {
    switch (orden) {
      case 'precio_asc':
        return 'precio';
      case 'precio_desc':
        return '-precio';
      case 'relevancia':
        return '-cantidad_favoritos';
      default:
        return '-creado_en';
    }
  }
}
