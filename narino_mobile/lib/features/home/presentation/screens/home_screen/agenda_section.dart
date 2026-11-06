import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../events/domain/event_model.dart';
import '../home_screen.dart';

/// Cuántos eventos próximos carga la agenda de Inicio.
const kHomeAgendaLimit = 100;

const _meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio',
  'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];
const _diasCortos = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

DateTime _soloDia(DateTime d) => DateTime(d.year, d.month, d.day);

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
    _selected = _soloDia(now);
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
      byDay.putIfAbsent(_soloDia(e.fecha.toLocal()), () => []).add(e);
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
            child: _Calendar(
              view: _view,
              selected: _selected,
              daysWithEvents: byDay.keys.toSet(),
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

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.view,
    required this.selected,
    required this.daysWithEvents,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });

  final DateTime view;
  final DateTime selected;
  final Set<DateTime> daysWithEvents;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final first = DateTime(view.year, view.month, 1);
    final total = DateTime(view.year, view.month + 1, 0).day;
    final prevTotal = DateTime(view.year, view.month, 0).day;
    final leading = first.weekday % 7; // domingo = 0

    final cells = <Widget>[
      for (var i = leading - 1; i >= 0; i--)
        _DayCell(label: '${prevTotal - i}', muted: true),
      for (var d = 1; d <= total; d++)
        () {
          final date = DateTime(view.year, view.month, d);
          return _DayCell(
            label: '$d',
            active: date == selected,
            hasEvent: daysWithEvents.contains(date),
            semantics: '$d de ${_meses[view.month - 1].toLowerCase()}'
                '${daysWithEvents.contains(date) ? ', con eventos' : ''}',
            onTap: () => onSelect(date),
          );
        }(),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_meses[view.month - 1]} ${view.year}',
                style: AppTypography.labelSemiBold(color: nc.textPrimary)
                    .copyWith(fontSize: 17),
              ),
            ),
            NcIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Mes anterior',
              bordered: false,
              size: 40,
              onPressed: onPrev,
            ),
            const SizedBox(width: 4),
            NcIconButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Mes siguiente',
              bordered: false,
              size: 40,
              onPressed: onNext,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final d in _diasCortos)
              Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption(color: nc.textSecondary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    this.muted = false,
    this.active = false,
    this.hasEvent = false,
    this.semantics,
    this.onTap,
  });

  final String label;
  final bool muted;
  final bool active;
  final bool hasEvent;
  final String? semantics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fg = active ? nc.onAzul : nc.textPrimary;
    final cell = Opacity(
      opacity: muted ? 0.3 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? nc.azul : Colors.transparent,
          boxShadow: active && nc.isDark
              ? [
                  BoxShadow(
                    color: AppColors.azulNeon.withValues(alpha: 0.4),
                    blurRadius: 15,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              label,
              style: AppTypography.labelMedium(color: fg).copyWith(
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (hasEvent)
              Positioned(
                bottom: 5,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? fg : nc.naranja,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap == null) return ExcludeSemantics(child: cell);
    return Semantics(
      label: semantics,
      selected: active,
      button: true,
      excludeSemantics: true,
      child: NcPressable(onTap: onTap, pressedScale: 0.88, child: cell),
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
        .where((e) => _soloDia(e.fecha.toLocal()).isAfter(day))
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Eventos del ${day.day} de ${_meses[day.month - 1].toLowerCase()}',
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
