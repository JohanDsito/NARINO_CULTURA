import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/event_model.dart';
import '../../widgets/eventos_ui.dart';

/// Cabecera con el flyer (o el ícono del tipo) y acciones de compartir.
class EventoAppBar extends StatelessWidget {
  const EventoAppBar({
    super.key,
    required this.event,
    required this.onCopiar,
    required this.onCompartir,
  });

  final EventModel event;
  final VoidCallback onCopiar;
  final VoidCallback onCompartir;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final accent = tipoAccent(nc, event.tipo);
    final flyer = event.flyerUrl;
    final respaldo = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.tint, nc.tomateA.tint],
        ),
      ),
      child: Center(
          child: Icon(tipoIcon(event.tipo), size: 56, color: accent.ink)),
    );

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: nc.bg,
      surfaceTintColor: Colors.transparent,
      shape: const Border(),
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: GlassCircleButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      actions: [
        GlassCircleButton(
          icon: Icons.link_rounded,
          tooltip: 'Copiar enlace',
          onPressed: onCopiar,
        ),
        const SizedBox(width: 8),
        GlassCircleButton(
          icon: Icons.ios_share_rounded,
          tooltip: 'Compartir',
          onPressed: onCompartir,
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (flyer != null && flyer.isNotEmpty)
              CachedNetworkImage(
                imageUrl: flyer,
                fit: BoxFit.cover,
                placeholder: (_, __) => respaldo,
                errorWidget: (_, __, ___) => respaldo,
              )
            else
              respaldo,
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              child: Container(
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: nc.bg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: const NcSerpentina(width: 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
