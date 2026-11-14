import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../events/domain/event_model.dart';

class AgendaDayEvents extends StatelessWidget {
  const AgendaDayEvents({
    super.key,
    required this.day,
    required this.events,
    required this.upcoming,
    required this.loading,
    required this.error,
  });

  final DateTime day;
  final List<EventModel> events;
  final List<EventModel> upcoming;
  final bool loading;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final titleStyle = AppTypography.labelSemiBold(color: nc.textPrimary)
        .copyWith(fontSize: 17);
    final emptyStyle = AppTypography.bodyMedium(color: nc.textSecondary);

    Widget item(EventModel e) {
      final desc = (e.descripcion?.trim().isNotEmpty ?? false)
          ? e.descripcion!
          : e.lugar;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: NcEventItem(
          time: NcEventItem.formatTime(e.fecha.toLocal()),
          title: e.nombre,
          description: desc,
          onTap: () => context.push('/events/${e.id}'),
        ),
      );
    }

    final proximos = upcoming
        .where((e) => soloDia(e.fecha.toLocal()).isAfter(day))
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Eventos del ${day.day} de ${kMesesNombre[day.month - 1].toLowerCase()}',
            style: titleStyle),
        const SizedBox(height: 16),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error)
          Text(
              'No pudimos cargar la agenda. Desliza hacia abajo para '
              'reintentar.',
              style: emptyStyle)
        else if (events.isNotEmpty)
          ...events.map(item)
        else ...[
          Text(
            'No hay eventos este día. Toca un día con punto naranja para ver '
            'la agenda.',
            style: emptyStyle,
          ),
          if (proximos.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Próximamente',
                style: AppTypography.caption(color: nc.oroA.ink)
                    .copyWith(fontSize: 12, letterSpacing: 0.6)),
            const SizedBox(height: 10),
            ...proximos.map(item),
          ],
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.go('/events'),
            child: const Text('Ver agenda completa →'),
          ),
        ),
      ],
    );
  }
}
