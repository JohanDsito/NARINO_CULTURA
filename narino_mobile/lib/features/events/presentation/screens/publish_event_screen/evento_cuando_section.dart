import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../widgets/eventos_ui.dart';

/// Duraciones que se ofrecen al publicar.
const kDuracionesEvento = <(String, Duration)>[
  ('1 h', Duration(hours: 1)),
  ('2 h', Duration(hours: 2)),
  ('3 h', Duration(hours: 3)),
  ('Medio día', Duration(hours: 5)),
  ('Todo el día', Duration(hours: 10)),
];

/// "¿Cuándo?": fecha y hora de inicio, duración y hora de fin calculada.
class EventoCuandoSection extends StatelessWidget {
  const EventoCuandoSection({
    super.key,
    required this.inicio,
    required this.duracion,
    required this.mostrarError,
    required this.onElegirFecha,
    required this.onDuracion,
  });

  final DateTime? inicio;
  final Duration duracion;

  /// Marca la fecha si se intentó publicar sin elegirla.
  final bool mostrarError;
  final VoidCallback onElegirFecha;
  final ValueChanged<Duration> onDuracion;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final falta = mostrarError && inicio == null;
    final fin = inicio?.add(duracion);
    return NcFormSection(
      title: '¿Cuándo?',
      children: [
        OutlinedButton.icon(
          onPressed: onElegirFecha,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: falta ? nc.tomateA.fill : nc.border),
          ),
          icon: const Icon(Icons.event_rounded),
          label: Text(inicio == null
              ? 'Elegir fecha y hora'
              : '${inicio!.day}/${inicio!.month}/${inicio!.year} · '
                  '${hora(inicio!)}'),
        ),
        if (falta) ...[
          const SizedBox(height: 6),
          Text('Elige cuándo empieza',
              style: AppTypography.bodySmall(color: nc.tomateA.ink)),
        ],
        const SizedBox(height: 14),
        Text('Duración',
            style: AppTypography.labelMedium(color: nc.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, d) in kDuracionesEvento)
              ChoiceChip(
                label: Text(label),
                selected: duracion == d,
                showCheckmark: false,
                onSelected: (_) => onDuracion(d),
                selectedColor: nc.eventos.fill,
                side: BorderSide(
                    color: duracion == d ? nc.eventos.fill : nc.border),
                labelStyle: AppTypography.labelMedium(
                  color: duracion == d ? nc.eventos.onFill : nc.textPrimary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
          ],
        ),
        if (fin != null) ...[
          const SizedBox(height: 12),
          Text(
              'Termina a las ${hora(fin)}'
              '${soloDia(fin) != soloDia(inicio!) ? ' del día siguiente' : ''}',
              style: AppTypography.labelSemiBold(color: nc.eventos.ink)
                  .copyWith(fontSize: 14)),
        ],
      ],
    );
  }
}
