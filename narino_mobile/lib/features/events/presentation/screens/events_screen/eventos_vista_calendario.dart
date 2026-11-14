import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/event_model.dart';
import '../../widgets/eventos_ui.dart';

class EventosVistaCalendario extends StatelessWidget {
  const EventosVistaCalendario({
    super.key,
    required this.eventos,
    required this.view,
    required this.selected,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });

  final List<EventModel> eventos;
  final DateTime view;
  final DateTime selected;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final porDia = <DateTime, List<EventModel>>{};
    for (final e in eventos) {
      porDia.putIfAbsent(soloDia(e.fecha.toLocal()), () => []).add(e);
    }
    final delDia = porDia[selected] ?? const <EventModel>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NcCard(
            child: NcMonthCalendar(
              view: view,
              selected: selected,
              markedDays: porDia.keys.toSet(),
              onPrev: onPrev,
              onNext: onNext,
              onSelect: onSelect,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Eventos del ${selected.day} de '
            '${kMesesNombre[selected.month - 1].toLowerCase()}',
            style: AppTypography.displaySemiBold(color: nc.textPrimary),
          ),
          const SizedBox(height: 12),
          if (delDia.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: nc.itemFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: nc.border),
              ),
              child: Text(
                'No hay eventos este día. Toca un día con punto naranja para '
                'ver su agenda.',
                style: AppTypography.bodyMedium(color: nc.textSecondary),
              ),
            )
          else
            for (final e in delDia)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EventoCard(event: e),
              ),
        ],
      ),
    );
  }
}
