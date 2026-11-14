import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/auction_model.dart';
import '../../widgets/subasta_ui.dart';
import 'segmentos_tiempo.dart';

/// Precio actual + cuenta regresiva + estado de liderazgo.
class MarcadorSubasta extends StatelessWidget {
  const MarcadorSubasta({
    super.key,
    required this.auction,
    required this.fase,
    required this.voyGanando,
  });

  final AuctionModel auction;
  final FaseSubasta fase;
  final bool voyGanando;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = auction;
    final hayPujas = a.pujadorLiderId != null || a.precioActual > a.precioBase;
    final mostrarTiempo =
        fase == FaseSubasta.enVivo || fase == FaseSubasta.programada;

    return NcCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fase == FaseSubasta.cerrada
                          ? 'PRECIO FINAL'
                          : (hayPujas ? 'PUJA ACTUAL' : 'PRECIO BASE'),
                      style: AppTypography.kicker(color: nc.oroA.ink),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (c, anim) => ScaleTransition(
                          scale: Tween(begin: 1.15, end: 1.0).animate(anim),
                          child: FadeTransition(opacity: anim, child: c)),
                      child: Text(
                        formatCOP(a.precioActual),
                        key: ValueKey(a.precioActual),
                        style:
                            AppTypography.displayBlack(color: nc.subastas.ink)
                                .copyWith(fontSize: 32),
                      ),
                    ),
                    if (hayPujas && fase != FaseSubasta.cerrada)
                      Text('Base ${formatCOP(a.precioBase)}',
                          style:
                              AppTypography.bodySmall(color: nc.textSecondary)),
                  ],
                ),
              ),
              if (voyGanando && fase == FaseSubasta.enVivo)
                NcStatusPill(
                  label: 'Vas ganando',
                  accent: nc.successA,
                  filled: true,
                  icon: Icons.emoji_events_outlined,
                ),
            ],
          ),
          if (mostrarTiempo) ...[
            const SizedBox(height: 16),
            const NcSerpentina(width: double.infinity, height: 3),
            const SizedBox(height: 16),
            NcCountdown(
              target: fase == FaseSubasta.programada
                  ? a.fechaInicio
                  : a.fechaCierre,
              builder: (_, r) => SegmentosTiempo(
                remaining: r,
                titulo:
                    fase == FaseSubasta.programada ? 'Empieza en' : 'Cierra en',
                urgente: fase == FaseSubasta.enVivo && r.inMinutes < 60,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
