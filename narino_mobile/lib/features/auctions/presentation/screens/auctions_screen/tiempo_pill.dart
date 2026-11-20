import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/auction_model.dart';
import '../../widgets/subasta_ui.dart';

/// Píldora de vidrio con la cuenta regresiva (cierre o inicio).
class TiempoPill extends StatelessWidget {
  const TiempoPill({super.key, required this.auction, required this.fase});

  final AuctionModel auction;
  final FaseSubasta fase;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final programada = fase == FaseSubasta.programada;
    return NcCountdown(
      target: programada ? auction.fechaInicio : auction.fechaCierre,
      builder: (_, r) {
        final urgente = !programada && r.inMinutes < 60;
        return Semantics(
          label: programada
              ? 'Empieza en ${NcCountdown.spoken(r)}'
              : 'Cierra en ${NcCountdown.spoken(r)}',
          excludeSemantics: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                color: urgente
                    ? nc.enVivo.fill
                    : Colors.black.withValues(alpha: 0.45),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      programada
                          ? Icons.event_available_rounded
                          : Icons.timer_outlined,
                      size: 15,
                      color: urgente ? nc.enVivo.onFill : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${programada ? 'Empieza en' : 'Cierra en'} '
                      '${NcCountdown.format(r)}',
                      style: AppTypography.labelMedium(
                              color: urgente ? nc.enVivo.onFill : Colors.white)
                          .copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
