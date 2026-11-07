import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/event_model.dart';

/// Tipos que acepta el backend (`Event.Type`), en minúscula.
const kTiposEvento = [
  'concierto',
  'exposicion',
  'taller',
  'feria',
  'espectaculo',
  'otro',
];

String tipoNombre(String tipo) => switch (tipo) {
      'concierto' => 'Concierto',
      'exposicion' => 'Exposición',
      'taller' => 'Taller',
      'feria' => 'Feria',
      'espectaculo' => 'Espectáculo',
      _ => 'Otro',
    };

IconData tipoIcon(String tipo) => switch (tipo) {
      'concierto' => Icons.music_note_rounded,
      'exposicion' => Icons.palette_outlined,
      'taller' => Icons.brush_outlined,
      'feria' => Icons.storefront_outlined,
      'espectaculo' => Icons.theater_comedy_outlined,
      _ => Icons.celebration_outlined,
    };

/// Cada tipo de evento con su color de carnaval.
NcAccent tipoAccent(NcColors nc, String tipo) => switch (tipo) {
      'concierto' => nc.musica,
      'exposicion' => nc.catalogo,
      'taller' => nc.naranjaA,
      'feria' => nc.oroA,
      'espectaculo' => nc.tomateA,
      _ => nc.azulA,
    };

const _diasLargos = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
];
const _diasCortos = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
const _mesesCortos = [
  'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
  'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
];

String hora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "sábado 12 de noviembre · 19:00 – 21:00"
String fechaLarga(EventModel e) {
  final f = e.fecha.toLocal();
  final fin = e.fechaFin;
  final rango = fin == null
      ? hora(f)
      : (soloDia(fin) == soloDia(f)
          ? '${hora(f)} – ${hora(fin)}'
          : '${hora(f)} · hasta el ${fin.day}/${fin.month}');
  return '${_diasLargos[f.weekday - 1]} ${f.day} de '
      '${kMesesNombre[f.month - 1].toLowerCase()} · $rango';
}

/// Tarjeta de evento con columna de fecha (día grande en tomate).
class EventoCard extends StatelessWidget {
  const EventoCard({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final f = event.fecha.toLocal();
    final accent = tipoAccent(nc, event.tipo);
    final img = event.flyerUrl;

    return Opacity(
      opacity: event.esPasado ? 0.6 : 1,
      child: NcCard(
        padding: const EdgeInsets.all(12),
        gradientBorder: false,
        onTap: () => context.push('/events/${event.id}'),
        child: Row(
          children: [
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: nc.eventos.tint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(_diasCortos[f.weekday - 1],
                      style: AppTypography.caption(color: nc.eventos.ink)
                          .copyWith(fontWeight: FontWeight.w800)),
                  Text('${f.day}',
                      style: AppTypography.displayBold(color: nc.eventos.ink)
                          .copyWith(fontSize: 24, height: 1.1)),
                  Text(_mesesCortos[f.month - 1],
                      style: AppTypography.caption(color: nc.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tipoIcon(event.tipo),
                              size: 14, color: accent.ink),
                          const SizedBox(width: 4),
                          Text(tipoNombre(event.tipo).toUpperCase(),
                              style: AppTypography.caption(color: accent.ink)
                                  .copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                      if (!event.publicado)
                        NcStatusPill(label: 'Borrador', accent: nc.oroA),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(event.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSemiBold(color: nc.textPrimary)
                          .copyWith(height: 1.25)),
                  const SizedBox(height: 4),
                  Text('${hora(f)} · ${event.lugar}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(color: nc.textSecondary)),
                ],
              ),
            ),
            if (img != null && img.isNotEmpty) ...[
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: img,
                  width: 56,
                  height: 72,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
