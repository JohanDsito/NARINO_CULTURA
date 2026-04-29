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
    if (estado != null && estado.isNotEmpty) qp['estado'] = estado;

    final r = await _dio.get(ApiConstants.auctions, queryParameters: qp);
    final data = r.data;
    if (data is List) return data;
    if (data is Map) return (data['results'] as List? ?? const []);
    return const [];
  }

  Future<Map<String, dynamic>> getAuctionDetail(int id) async {
    final r = await _dio.get('${ApiConstants.auctions}$id/');
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createAuction({
    required int obraId,
    required double precioBase,
    required int duracionDias,
    required DateTime fechaInicio,
  }) async {
    final r = await _dio.post(
      ApiConstants.auctions,
      data: {
        'obra_id': obraId,
        'precio_base': precioBase,
        'duracion_dias': duracionDias,
        'fecha_inicio': fechaInicio.toIso8601String(),
      },
    );
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> bid({
    required int auctionId,
    required double monto,
  }) async {
    final url =
        ApiConstants.auctionBid.replaceFirst('{id}', auctionId.toString());
    final r = await _dio.post(url, data: {'monto': monto});
    return (r.data as Map).cast<String, dynamic>();
  }
}
