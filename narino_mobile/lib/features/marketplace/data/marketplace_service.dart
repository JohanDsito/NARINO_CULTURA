import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class MarketplaceService {
  Dio get _dio => ApiClient.instance.dio;

  // ── helpers ──────────────────────────────────────────────────────────────

  /// Obras del catálogo indexadas por id, buscando solo las de [ids].
  ///
  /// Usa la LISTA paginada (no `GET /artworks/{id}/`, que suma una vista cada
  /// vez) y se detiene apenas encuentra todas o se acaban las páginas.
  Future<Map<String, Map<String, dynamic>>> _artworksById(Set<String> ids) async {
    final found = <String, Map<String, dynamic>>{};
    if (ids.isEmpty) return found;
    String? nextUrl = ApiConstants.artworks;
    Map<String, dynamic>? query = {'page_size': 100};
    var pages = 0;
    try {
      while (nextUrl != null && found.length < ids.length && pages < 5) {
        final r = await _dio.get(nextUrl, queryParameters: query);
        query = null; // `next` ya trae los parámetros
        pages++;
        final data = r.data;
        final results = data is Map ? data['results'] as List? ?? const [] : const [];
        for (final item in results.whereType<Map>()) {
          final id = item['id']?.toString();
          if (id != null && ids.contains(id)) {
            found[id] = item.cast<String, dynamic>();
          }
        }
        final next = data is Map ? data['next']?.toString() : null;
        nextUrl = (next != null && next.isNotEmpty) ? next : null;
      }
    } catch (_) {
      // Sin enriquecimiento: la lista se muestra con los datos básicos.
    }
    return found;
  }

  String _nameFromSlug(String? slug) {
    if (slug == null || slug.isEmpty) return '';
    return slug
        .split('-')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // ── carrito ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _rawCart() async {
    final r = await _dio.get(ApiConstants.cart);
    final data = r.data;
    final List<dynamic> raw;
    if (data is List) {
      raw = data;
    } else if (data is Map) {
      raw = (data['items'] as List?) ?? (data['results'] as List?) ?? [];
    } else {
      return [];
    }
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  /// Carrito. El backend ya trae título, precio y estado de cada obra; solo
  /// falta imagen y artista, que se completan con una sola consulta de lista.
  Future<List<dynamic>> getCart() async {
    final items = await _rawCart();
    final obras = await _artworksById(
      items.map((i) => i['artwork']?.toString() ?? '').where((id) => id.isNotEmpty).toSet(),
    );
    return items.map((item) {
      final base = Map<String, dynamic>.from(item);
      final obra = obras[base['artwork']?.toString()];
      if (obra != null) {
        base['artista_nombre'] = obra['artista_nombre']?.toString() ??
            _nameFromSlug(obra['artist_slug']?.toString());
        base['imagen_url'] = obra['main_image_url']?.toString() ?? '';
      }
      return base;
    }).toList();
  }

  Future<void> addToCart(String obraId) async {
    await _dio.post(ApiConstants.cartItems, data: {'artwork_id': obraId});
  }

  Future<void> removeFromCart(String obraId) async {
    await _dio.delete(
      ApiConstants.cartItems,
      data: {'artwork_id': obraId},
    );
  }

  Future<void> clearCart() async {
    final items = await _rawCart();
    for (final item in items) {
      final obraId = item['artwork']?.toString() ?? item['obra_id']?.toString();
      if (obraId != null && obraId.isNotEmpty) {
        try {
          await removeFromCart(obraId);
        } catch (_) {}
      }
    }
  }

  /// Favoritos. El backend solo trae `artwork` (id) y `artwork_title`; el
  /// resto (imagen, precio, estado, artista) se completa con la lista.
  Future<List<dynamic>> getFavorites() async {
    final r = await _dio.get(ApiConstants.favorites);
    final List<dynamic> raw = r.data is List
        ? r.data as List
        : (r.data['results'] as List? ?? []);
    final favs = raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();

    String idDe(Map<String, dynamic> f) =>
        (f['artwork'] ?? f['artwork_id'] ?? '').toString();

    final obras = await _artworksById(
      favs.map(idDe).where((id) => id.isNotEmpty).toSet(),
    );
    return favs.map((fav) {
      final base = Map<String, dynamic>.from(fav);
      final obra = obras[idDe(fav)];
      if (obra != null) {
        base['artista_nombre'] = obra['artista_nombre']?.toString() ??
            _nameFromSlug(obra['artist_slug']?.toString());
        base['status'] = obra['status'];
        base['price'] = obra['price'];
        base['main_image_url'] = obra['main_image_url'];
        if ((base['artwork_title']?.toString() ?? '').isEmpty) {
          base['title'] = obra['title'];
        }
      }
      return base;
    }).toList();
  }

  Future<void> addFavorite(String obraId) async {
    try {
      await _dio.post(ApiConstants.favorites, data: {'artwork_id': obraId});
    } on DioException catch (e) {
      // 400 = restricción única: ya es favorito → idempotente, no lanzar
      if (e.response?.statusCode != 400) rethrow;
    }
  }

  Future<void> removeFavorite(String obraId) async {
    try {
      await _dio.delete(ApiConstants.favorites, data: {'artwork_id': obraId});
    } on DioException catch (e) {
      // 400 = no era favorito → idempotente, no lanzar
      if (e.response?.statusCode != 400) rethrow;
    }
  }

  Future<Map<String, dynamic>> createOrder() async {
    final r = await _dio.post(ApiConstants.checkout);
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> getOrders() async {
    final r = await _dio.get(ApiConstants.orders);
    return r.data is List
        ? r.data as List
        : (r.data['results'] as List? ?? []);
  }

  Future<Map<String, dynamic>> getOrderDetail(String id) async {
    try {
      final url = ApiConstants.orderDetail.replaceAll('{id}', id);
      final r = await _dio.get(url);
      return (r.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      // Si el endpoint individual no existe en el backend, filtramos la lista
      if (e.response?.statusCode == 404) {
        final orders = await getOrders();
        final order = orders.firstWhere(
          (o) => o['id']?.toString() == id || o['order_id']?.toString() == id,
          orElse: () => <String, dynamic>{},
        );
        if ((order as Map).isNotEmpty) return Map<String, dynamic>.from(order);
        return {'id': id, 'items': [], 'status': 'unknown', 'total_amount': 0};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiatePayment(String orderId) async {
    final r = await _dio.post(
      ApiConstants.initiatePayment,
      data: {'order_id': orderId},
    );
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    final orders = await getOrders();
    final order = orders.firstWhere(
      (o) => o['id']?.toString() == orderId,
      orElse: () => <String, dynamic>{},
    );
    final rawStatus =
        (order as Map)['status']?.toString().toUpperCase() ?? 'PENDIENTE';
    final normalizedStatus = switch (rawStatus) {
      'PAGADO' => 'completado',
      'CANCELADO' => 'fallido',
      'REEMBOLSADO' => 'reembolsado',
      _ => 'pendiente',
    };
    return {'status': normalizedStatus};
  }

  Future<List<dynamic>> getPurchaseHistory() async {
    return getOrders();
  }

  Future<List<dynamic>> getSalesHistory() async {
    final r = await _dio.get(ApiConstants.salesHistory);
    return r.data is List
        ? r.data as List
        : (r.data['results'] as List? ?? []);
  }
}
