import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../events/domain/event_model.dart';
import '../home_screen.dart';
import 'agenda_day_events.dart';

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
            child: AgendaDayEvents(
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
