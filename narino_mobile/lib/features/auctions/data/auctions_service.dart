import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class AuctionsService {
  Dio get _dio => ApiClient.instance.dio;

  /// Lista de subastas. El backend solo filtra por `status`
  /// (PENDIENTE, ACTIVA, CERRADA, CANCELADA); el resto se filtra en la app.
  /// Cada subasta se completa con título, imagen y artista de su obra.
  Future<List<dynamic>> getAuctions({String? estado}) async {
    final qp = <String, dynamic>{'page_size': 100};
    if (estado != null && estado.isNotEmpty) qp['status'] = estado.toUpperCase();

    final r = await _dio.get(ApiConstants.auctions, queryParameters: qp);
    final data = r.data;
    final raw = data is List
        ? data
        : (data is Map ? (data['results'] as List? ?? const []) : const []);
    final subastas =
        raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();

    final ids = subastas.map(_obraId).where((id) => id.isNotEmpty).toSet();
    final obras = await _artworksById(ids);
    return subastas.map((s) => _conObra(s, obras[_obraId(s)])).toList();
  }

  static String _obraId(Map<String, dynamic> s) =>
      (s['artwork_id'] ?? s['artwork'] ?? '').toString();

  /// Copia los datos de la obra a las claves que lee `AuctionModel.fromJson`.
  static Map<String, dynamic> _conObra(
      Map<String, dynamic> subasta, Map<String, dynamic>? obra) {
    if (obra == null) return subasta;
    final slug = obra['artist_slug']?.toString() ?? '';
    return {
      ...subasta,
      'obra_titulo': obra['title'],
      'imagen_url': obra['main_image_url'],
      'artista_nombre': obra['artista_nombre'] ??
          slug
              .split('-')
              .where((w) => w.isNotEmpty)
              .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
              .join(' '),
    };
  }

  /// Busca las obras por id en la LISTA (el detalle suma vistas). Primero las
  /// que están en subasta y, si falta alguna, recorre el catálogo general.
  Future<Map<String, Map<String, dynamic>>> _artworksById(Set<String> ids) async {
    final found = <String, Map<String, dynamic>>{};
    if (ids.isEmpty) return found;

    Future<void> recorrer(Map<String, dynamic> query, int maxPaginas) async {
      String? nextUrl = ApiConstants.artworks;
      Map<String, dynamic>? qp = query;
      var paginas = 0;
      while (nextUrl != null &&
          found.length < ids.length &&
          paginas < maxPaginas) {
        final r = await _dio.get(nextUrl, queryParameters: qp);
        qp = null; // `next` ya trae los parámetros
        paginas++;
        final data = r.data;
        final results =
            data is Map ? data['results'] as List? ?? const [] : const [];
        for (final item in results.whereType<Map>()) {
          final id = item['id']?.toString();
          if (id != null && ids.contains(id)) {
            found[id] = item.cast<String, dynamic>();
          }
        }
        final next = data is Map ? data['next']?.toString() : null;
        nextUrl = (next != null && next.isNotEmpty) ? next : null;
      }
    }

    try {
      await recorrer({'status': 'EN_SUBASTA', 'page_size': 100}, 3);
      if (found.length < ids.length) await recorrer({'page_size': 100}, 3);
    } catch (_) {
      // Sin enriquecimiento: la tarjeta muestra los datos básicos.
    }
    return found;
  }

  Future<Map<String, dynamic>> getAuctionDetail(String id) async {
    final r = await _dio.get('${ApiConstants.auctions}$id/');
    final subasta = (r.data as Map).cast<String, dynamic>();
    final obraId = _obraId(subasta);
    if (obraId.isEmpty) return subasta;
    // En el detalle sí se abre la obra: es una visita real del usuario.
    try {
      final o = await _dio
          .get(ApiConstants.artworkDetail.replaceAll('{id}', obraId));
      return _conObra(subasta, (o.data as Map).cast<String, dynamic>());
    } catch (_) {
      return subasta;
    }
  }

  Future<Map<String, dynamic>> createAuction({
    required String obraId,
    required double precioBase,
    required int duracionDias,
    required DateTime fechaInicio,
  }) async {
    final startsAt = fechaInicio;
    final endsAt = fechaInicio.add(Duration(days: duracionDias));
    final r = await _dio.post(
      ApiConstants.auctions,
      data: {
        'artwork': obraId,
        'base_price': precioBase,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
      },
    );
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> bid({
    required String auctionId,
    required double monto,
  }) async {
    final url = ApiConstants.auctionBid.replaceFirst('{id}', auctionId);
    final r = await _dio.post(url, data: {'amount': monto});
    return (r.data as Map).cast<String, dynamic>();
  }
}
