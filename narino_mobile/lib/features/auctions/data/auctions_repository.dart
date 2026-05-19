import 'package:dio/dio.dart';

import '../domain/auction_model.dart';
import 'auctions_service.dart';

/// Repositorio de subastas: integra endpoints REST y acciones CRUD relacionadas
/// con subastas (listado, detalle, crear, pujar, cancelar, historial).
class AuctionsRepository {
  AuctionsRepository({AuctionsService? service})
    : _service = service ?? AuctionsService();

  final AuctionsService _service;

  Future<List<AuctionModel>> getAuctions({
    String? participante,
    String? artista,
    String? estado,
  }) async {
    try {
      final data = await _service.getAuctions(
        participante: participante,
        artista: artista,
        estado: estado,
      );
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

  String _err(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar al servidor.';
    }

    final code = e.response?.statusCode;
    final body = e.response?.data;

    if (code == 401) return 'Tu sesión expiró. Inicia sesión nuevamente.';
    if (code == 403) {
      final extracted = _extractMessage(body);
      return extracted ?? 'No tienes permiso para realizar esta acción.';
    }
    if (code == 404) return 'Subasta no encontrada.';

    final extracted = _extractMessage(body);
    if (extracted != null && extracted.isNotEmpty) return extracted;

    return 'Ocurrió un error inesperado.';
  }

  String? _extractMessage(Object? data) {
    if (data is Map) {
      final detail = data['detail']?.toString();
      if (detail != null && detail.isNotEmpty) return detail;

      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          final msg = value.first?.toString();
          if (msg != null && msg.isNotEmpty) return msg;
        }
      }
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
