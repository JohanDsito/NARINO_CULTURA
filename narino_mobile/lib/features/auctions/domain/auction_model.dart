import 'auction_bid_model.dart';

/// Modelo de dominio que representa una subasta asociada a una obra.
class AuctionModel {
  final String id;
  final String obraId;
  final String obraTitulo;
  final String artistaNombre;
  final String? imagenUrl;
  final double precioBase;
  final double precioActual;
  final int totalPujas;
  final DateTime fechaInicio;
  final DateTime fechaCierre;
  final String estado;
  final String? ganadorNombre;
  final List<AuctionBidModel> ultimasPujas;

  final String? artistaId;
  final String? ganadorId;
  final String? orderId;

  const AuctionModel({
    required this.id,
    required this.obraId,
    required this.obraTitulo,
    required this.artistaNombre,
    required this.imagenUrl,
    required this.precioBase,
    required this.precioActual,
    required this.totalPujas,
    required this.fechaInicio,
    required this.fechaCierre,
    required this.estado,
    required this.ganadorNombre,
    required this.ultimasPujas,
    this.artistaId,
    this.ganadorId,
    this.orderId,
  });

  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    final obraRaw = json['obra'];
    final obraMap = obraRaw is Map ? obraRaw.cast<String, dynamic>() : null;

    final rawPrecioBase = json['precio_base'] ?? json['precioBase'];
    final rawPrecioActual = json['precio_actual'] ?? json['precioActual'];

    final precioBase = rawPrecioBase is num
        ? rawPrecioBase.toDouble()
        : double.tryParse(rawPrecioBase?.toString() ?? '') ?? 0.0;
    final precioActual = rawPrecioActual is num
        ? rawPrecioActual.toDouble()
        : double.tryParse(rawPrecioActual?.toString() ?? '') ?? precioBase;

    final rawInicio = json['fecha_inicio'] ?? json['fechaInicio'];
    final rawCierre = json['fecha_cierre'] ?? json['fechaCierre'];

    final inicio =
        DateTime.tryParse(rawInicio?.toString() ?? '') ?? DateTime.now();
    final cierre =
        DateTime.tryParse(rawCierre?.toString() ?? '') ?? DateTime.now();

    final bidsRaw = json['ultimas_pujas'] ??
        json['bids'] ??
        json['pujas'] ??
        const <dynamic>[];
    final bidsList = (bidsRaw is List ? bidsRaw : const <dynamic>[])
        .whereType<Map>()
        .map((e) => AuctionBidModel.fromJson(e.cast<String, dynamic>()))
        .toList();

    final id = (json['id'] ?? json['obraId'])?.toString() ?? '';
    final obraId = (json['obra_id'] ?? obraMap?['id'] ?? json['obraId'])?.toString() ?? '';

    final obraTitulo = (json['obra_titulo'] ??
            json['obraTitulo'] ??
            obraMap?['titulo'] ??
            obraMap?['nombre'])
        ?.toString();

    final artistaNombre =
        (json['artista_nombre'] ?? json['artistaNombre'] ?? json['artista'])
            ?.toString();

    final imagenUrl = (json['imagen_url'] ??
            json['imagenUrl'] ??
            obraMap?['imagen_url'] ??
            obraMap?['imagen_principal'] ??
            obraMap?['imagen'])
        ?.toString();

    final totalPujas = json['total_pujas'] ?? json['totalPujas'];
    final totalPujasInt = totalPujas is int
        ? totalPujas
        : (int.tryParse(totalPujas?.toString() ?? '') ?? bidsList.length);

    return AuctionModel(
      id: id,
      obraId: obraId,
      obraTitulo: obraTitulo ?? 'Obra',
      artistaNombre: artistaNombre ?? 'Artista',
      imagenUrl: (imagenUrl != null && imagenUrl.trim().isNotEmpty)
          ? imagenUrl.trim()
          : null,
      precioBase: precioBase,
      precioActual: precioActual,
      totalPujas: totalPujasInt,
      fechaInicio: inicio,
      fechaCierre: cierre,
      estado: (json['estado'] ?? json['status'])?.toString() ?? 'activa',
      ganadorNombre:
          (json['ganador_nombre'] ?? json['ganadorNombre'] ?? json['ganador'])
              ?.toString(),
      ultimasPujas: bidsList,
      artistaId: (json['artista_id'] ?? json['artistaId'])?.toString(),
      ganadorId: (json['ganador_id'] ?? json['ganadorId'])?.toString(),
      orderId: (json['order_id'] ?? json['orderId'])?.toString(),
    );
  }

  AuctionModel copyWith({
    double? precioActual,
    int? totalPujas,
    String? estado,
    String? ganadorNombre,
    String? ganadorId,
    String? orderId,
    List<AuctionBidModel>? ultimasPujas,
    DateTime? fechaCierre,
  }) {
    return AuctionModel(
      id: id,
      obraId: obraId,
      obraTitulo: obraTitulo,
      artistaNombre: artistaNombre,
      imagenUrl: imagenUrl,
      precioBase: precioBase,
      precioActual: precioActual ?? this.precioActual,
      totalPujas: totalPujas ?? this.totalPujas,
      fechaInicio: fechaInicio,
      fechaCierre: fechaCierre ?? this.fechaCierre,
      estado: estado ?? this.estado,
      ganadorNombre: ganadorNombre ?? this.ganadorNombre,
      ultimasPujas: ultimasPujas ?? this.ultimasPujas,
      artistaId: artistaId,
      ganadorId: ganadorId ?? this.ganadorId,
      orderId: orderId ?? this.orderId,
    );
  }
}
