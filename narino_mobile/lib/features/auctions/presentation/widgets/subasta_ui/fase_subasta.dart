import '../../../domain/auction_model.dart';

/// Fase visible de una subasta (combina `status` y fechas).
enum FaseSubasta { pendiente, programada, enVivo, cerrada, cancelada }

FaseSubasta faseDe(AuctionModel a, {DateTime? now}) {
  final t = now ?? DateTime.now();
  return switch (a.estado) {
    'pendiente' => FaseSubasta.pendiente,
    'cancelada' => FaseSubasta.cancelada,
    'cerrada' => FaseSubasta.cerrada,
    _ => a.fechaInicio.isAfter(t)
        ? FaseSubasta.programada
        : (a.fechaCierre.isAfter(t) ? FaseSubasta.enVivo : FaseSubasta.cerrada),
  };
}
