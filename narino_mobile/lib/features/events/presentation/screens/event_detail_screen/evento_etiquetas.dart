import 'package:flutter/material.dart';

import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/event_model.dart';
import '../../widgets/eventos_ui.dart';

/// Pastillas del evento: tipo, destacado, ya pasó y borrador.
class EventoEtiquetas extends StatelessWidget {
  const EventoEtiquetas({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final e = event;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        NcStatusPill(
          label: tipoNombre(e.tipo),
          accent: tipoAccent(nc, e.tipo),
          icon: tipoIcon(e.tipo),
          filled: true,
        ),
        if (e.esDestacado)
          NcStatusPill(
              label: 'Destacado', accent: nc.oroA, icon: Icons.star_rounded),
        if (e.esPasado) NcStatusPill(label: 'Ya pasó', accent: nc.azulA),
        if (!e.publicado) NcStatusPill(label: 'Borrador', accent: nc.oroA),
      ],
    );
  }
}
