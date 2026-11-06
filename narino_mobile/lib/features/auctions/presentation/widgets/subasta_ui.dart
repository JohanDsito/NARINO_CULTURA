import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../domain/auction_model.dart';

export '../../../../core/utils/money.dart' show formatCOP;

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

/// Punto que late (como "grabando"). Respeta "reducir movimiento".
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    reduce ? _c.stop() : _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: widget.color.withValues(alpha: 0.6), blurRadius: 6),
          ],
        ),
      ),
    );
  }
}

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

/// Imagen de la obra subastada con respaldo dorado.
class SubastaImage extends StatelessWidget {
  const SubastaImage({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nc.oroA.tint, nc.tomateA.tint],
        ),
      ),
      child: Center(
        child: Icon(Icons.gavel_rounded, size: 40, color: nc.subastas.ink),
      ),
    );
    if (url == null || url!.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
