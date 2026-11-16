import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../domain/auction_model.dart';
import 'auctions_service.dart';

/// Repositorio de subastas: integra endpoints REST y acciones CRUD relacionadas
/// con subastas (listado, detalle, crear, pujar, cancelar, historial).
class AuctionsRepository {
  AuctionsRepository({AuctionsService? service})
    : _service = service ?? AuctionsService();

  final AuctionsService _service;

  Future<List<AuctionModel>> getAuctions({
    String? estado,
    bool mine = false,
    bool participating = false,
  }) async {
    try {
      final data = await _service.getAuctions(
          estado: estado, mine: mine, participating: participating);
      return data
          .whereType<Map>()
          .map((e) => AuctionModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<AuctionModel> getDetail(String id) async {
    try {
      return AuctionModel.fromJson(await _service.getAuctionDetail(id));
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<AuctionModel> createAuction({
    required String obraId,
    required double precioBase,
    required int duracionDias,
    required DateTime fechaInicio,
  }) async {
    try {
      final data = await _service.createAuction(
        obraId: obraId,
        precioBase: precioBase,
        duracionDias: duracionDias,
        fechaInicio: fechaInicio,
      );
      return AuctionModel.fromJson(data);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> bid({required String auctionId, required double monto}) async {
    try {
      await _service.bid(auctionId: auctionId, monto: monto);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  String _err(DioException e) =>
      ApiError.message(e, byStatus: const {404: 'Subasta no encontrada.'});
}
