import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../events/domain/event_model.dart';
import '../home_screen.dart';

/// Cuántos eventos próximos carga la agenda de Inicio.
const kHomeAgendaLimit = 100;

/// Agenda & Eventos: calendario mensual con puntos naranja en los días con
/// eventos y, debajo, los eventos del día elegido.
class AgendaSection extends ConsumerStatefulWidget {
  const AgendaSection({super.key});

  @override
  ConsumerState<AgendaSection> createState() => _AgendaSectionState();
}

class _AgendaSectionState extends ConsumerState<AgendaSection> {
  late DateTime _view; // primer día del mes visible
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = soloDia(now);
    _view = DateTime(now.year, now.month);
  }

  void _moveMonth(int delta) =>
      setState(() => _view = DateTime(_view.year, _view.month + delta));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(homeUpcomingEventsProvider(kHomeAgendaLimit));
    final events = async.valueOrNull ?? const <EventModel>[];

    final byDay = <DateTime, List<EventModel>>{};
    for (final e in events) {
      byDay.putIfAbsent(soloDia(e.fecha.toLocal()), () => []).add(e);
    }
    final ofDay = byDay[_selected] ?? const <EventModel>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NcSectionHeader(
            title: 'Agenda & Eventos',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          NcCard(
            child: NcMonthCalendar(
              view: _view,
              selected: _selected,
              markedDays: byDay.keys.toSet(),
              onPrev: () => _moveMonth(-1),
              onNext: () => _moveMonth(1),
              onSelect: (d) => setState(() => _selected = d),
            ),
          ),
          const SizedBox(height: 16),
          NcCard(
            child: _DayEvents(
              day: _selected,
              events: ofDay,
              upcoming: events,
              loading: async.isLoading && events.isEmpty,
              error: async.hasError && events.isEmpty,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayEvents extends StatelessWidget {
  const _DayEvents({
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
        Text('Eventos del ${day.day} de ${kMesesNombre[day.month - 1].toLowerCase()}',
            style: titleStyle),
        const SizedBox(height: 16),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error)
          Text('No pudimos cargar la agenda. Desliza hacia abajo para '
              'reintentar.', style: emptyStyle)
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
