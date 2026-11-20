import 'package:flutter/material.dart';

import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/auction_model.dart';
import '../../widgets/subasta_ui.dart';
import 'ganaste_subasta_card.dart';

/// Avisos según la fase: en revisión, programada, cancelada, es tuya,
/// ganaste (con botón de pago) o terminó.
class AvisosSubasta extends StatelessWidget {
  const AvisosSubasta({
    super.key,
    required this.auction,
    required this.fase,
    required this.soyVendedor,
    required this.gane,
  });

  final AuctionModel auction;
  final FaseSubasta fase;
  final bool soyVendedor;
  final bool gane;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = auction;
    Widget gap(Widget w) =>
        Padding(padding: const EdgeInsets.only(bottom: 12), child: w);
    String dosDigitos(int v) => v.toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fase == FaseSubasta.pendiente)
          gap(NcBanner(
            accent: nc.oroA,
            icon: Icons.hourglass_top_rounded,
            message: soyVendedor
                ? 'Tu subasta está en revisión. Un administrador la aprobará '
                    'antes de que salga en vivo.'
                : 'Esta subasta aún no ha sido aprobada.',
          )),
        if (fase == FaseSubasta.programada)
          gap(NcBanner(
            accent: nc.azulA,
            icon: Icons.event_available_rounded,
            message: 'Las pujas se abren el '
                '${a.fechaInicio.day}/${a.fechaInicio.month} a las '
                '${dosDigitos(a.fechaInicio.hour)}:'
                '${dosDigitos(a.fechaInicio.minute)}.',
          )),
        if (fase == FaseSubasta.cancelada)
          gap(NcBanner(
            accent: nc.tomateA,
            icon: Icons.block_rounded,
            message: 'Esta subasta fue cancelada.',
          )),
        if (soyVendedor && fase == FaseSubasta.enVivo)
          gap(NcBanner(
            accent: nc.subastas,
            icon: Icons.visibility_outlined,
            message: 'Es tu subasta: puedes seguir las pujas en vivo, pero no '
                'pujar.',
          )),
        if (fase == FaseSubasta.cerrada && gane)
          gap(GanasteSubastaCard(auction: a)),
        if (fase == FaseSubasta.cerrada && !gane)
          gap(NcBanner(
            accent: nc.subastas,
            icon: Icons.flag_outlined,
            message: a.ganadorId == null
                ? 'La subasta terminó sin pujas.'
                : soyVendedor
                    ? '¡Tu obra se subastó por ${formatCOP(a.precioActual)}!'
                    : 'La subasta terminó en ${formatCOP(a.precioActual)}.',
          )),
      ],
    );
  }
}
