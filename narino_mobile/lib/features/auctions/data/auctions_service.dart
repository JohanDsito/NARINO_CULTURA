import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class AuctionsService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<dynamic>> getAuctions({
    String? participante,
    String? artista,
    String? estado,
  }) async {
    final qp = <String, dynamic>{};
    if (participante != null) qp['participante'] = participante;
    if (artista != null) qp['artista'] = artista;
    // Backend uses 'status' with uppercase values (ACTIVA, CERRADA, CANCELADA)
    if (estado != null && estado.isNotEmpty) qp['status'] = estado.toUpperCase();

    final r = await _dio.get(ApiConstants.auctions, queryParameters: qp);
    final data = r.data;
    if (data is List) return data;
    if (data is Map) return (data['results'] as List? ?? const []);
    return const [];
  }

  Future<Map<String, dynamic>> getAuctionDetail(String id) async {
    final r = await _dio.get('${ApiConstants.auctions}$id/');
    return (r.data as Map).cast<String, dynamic>();
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
