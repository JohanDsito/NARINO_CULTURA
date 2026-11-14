import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import 'fase_subasta.dart';
import 'live_dot.dart';

String faseLabel(FaseSubasta f) => switch (f) {
      FaseSubasta.pendiente => 'Esperando aprobación',
      FaseSubasta.programada => 'Próximamente',
      FaseSubasta.enVivo => 'En vivo',
      FaseSubasta.cerrada => 'Finalizada',
      FaseSubasta.cancelada => 'Cancelada',
    };

NcAccent faseAccent(NcColors nc, FaseSubasta f) => switch (f) {
      FaseSubasta.pendiente => nc.oroA,
      FaseSubasta.programada => nc.azulA,
      FaseSubasta.enVivo => nc.enVivo,
      FaseSubasta.cerrada => nc.subastas,
      FaseSubasta.cancelada => nc.tomateA,
    };

/// Insignia de fase en píldora; "En vivo" lleva el punto que late.
class FaseBadge extends StatelessWidget {
  const FaseBadge({super.key, required this.fase, this.onImage = false});

  final FaseSubasta fase;

  /// Sobre una foto usa relleno sólido para que se lea.
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = faseAccent(nc, fase);
    final filled = onImage || fase == FaseSubasta.enVivo;
    final fg = filled ? a.onFill : a.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? a.fill : a.tint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fase == FaseSubasta.enVivo) ...[
            LiveDot(color: fg, size: 7),
            const SizedBox(width: 6),
          ],
          Text(faseLabel(fase).toUpperCase(),
              style: AppTypography.caption(color: fg)
                  .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6)),
        ],
      ),
    );
  }
}
