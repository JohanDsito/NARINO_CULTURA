import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class ArtworkService {
  Dio get _dio => ApiClient.instance.dio;

  /// Catálogo público.
  ///
  /// El backend solo filtra por `category` (id), `status`, `search` y ordena
  /// por `created_at`, `price` o `views_count`. La técnica y el rango de precio
  /// no existen como filtro en el servidor, así que cuando están activos se
  /// pide una página grande y se filtra aquí.
  Future<Map<String, dynamic>> getCatalog({
    String? search,
    String? categoria,
    String? tecnica,
    double? precioMin,
    double? precioMax,
    String ordenarPor = 'fecha',
    int page = 1,
  }) async {
    // Todos los filtros van al servidor (?technique= contiene, ?price_min=,
    // ?price_max=): así la paginación y el total son reales. Antes técnica y
    // precio se filtraban en el teléfono solo dentro de las primeras 100.
    String precio(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    final queryParams = <String, dynamic>{
      'ordering': _mapOrden(ordenarPor),
      'page': page,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoria != null && categoria.isNotEmpty) 'category': categoria,
      if (tecnica != null && tecnica.trim().isNotEmpty)
        'technique': tecnica.trim(),
      if (precioMin != null) 'price_min': precio(precioMin),
      if (precioMax != null) 'price_max': precio(precioMax),
    };

    final response = await _dio.get(
      ApiConstants.artworks,
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Obras disponibles para comprar (Tienda), filtradas en el servidor.
  Future<Map<String, dynamic>> getDisponibles({int pageSize = 60}) async {
    final response = await _dio.get(
      ApiConstants.artworks,
      queryParameters: {
        'status': 'DISPONIBLE',
        'ordering': '-created_at',
        'page_size': pageSize,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getArtworkDetail(String id) async {
    final url = ApiConstants.artworkDetail.replaceAll('{id}', id);
    final response = await _dio.get(url);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getCategories() async {
    final response = await _dio.get(ApiConstants.artworkCategories);
    final data = response.data;
    if (data is Map && data['results'] is List) return data['results'] as List;
    if (data is List) return data;
    return const [];
  }

  /// Todas las obras publicadas por el artista [slug] (filtrado en el
  /// servidor, siguiendo la paginación si el backend la aplica).
  Future<List<Map<String, dynamic>>> getByArtist(String slug) async {
    final results = <Map<String, dynamic>>[];
    String? nextUrl = ApiConstants.artworks;
    Map<String, dynamic>? queryParameters = {
      'artist': slug,
      'page_size': 100,
    };
    while (nextUrl != null) {
      final res = await _dio.get(nextUrl, queryParameters: queryParameters);
      queryParameters = null; // ya va codificado en la URL `next` del backend
      final data = res.data;
      if (data is Map) {
        results.addAll((data['results'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>()));
        final next = data['next']?.toString();
        nextUrl = (next != null && next.isNotEmpty) ? next : null;
      } else if (data is List) {
        results.addAll(data.whereType<Map>().map((e) => e.cast<String, dynamic>()));
        nextUrl = null;
      } else {
        break;
      }
    }
    return results;
  }

  Future<Map<String, dynamic>> publishArtwork(FormData formData) async {
    final response = await _dio.post(
      ApiConstants.artworks,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateArtwork(String id, FormData formData) async {
    final url = ApiConstants.artworkDetail.replaceAll('{id}', id);
    final response = await _dio.patch(
      url,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteArtwork(String id) async {
    final url = ApiConstants.artworkDetail.replaceAll('{id}', id);
    await _dio.delete(url);
  }

  Future<Map<String, dynamic>> toggleFavorite(String artworkId) async {
    try {
      await _dio.post(
        ApiConstants.favorites,
        data: {'artwork_id': artworkId},
      );
      return {'es_favorito': true};
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        await _dio.delete(
          ApiConstants.favorites,
          data: {'artwork_id': artworkId},
        );
        return {'es_favorito': false};
      }
      rethrow;
    }
  }

  String _mapOrden(String orden) {
    switch (orden) {
      case 'precio_asc':
        return 'price';
      case 'precio_desc':
        return '-price';
      case 'relevancia':
        return '-views_count';
      default:
        return '-created_at';
    }
  }
}
