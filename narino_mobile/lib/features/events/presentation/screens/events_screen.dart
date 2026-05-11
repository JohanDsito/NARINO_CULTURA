import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/event_model.dart';
import '../../domain/events_state.dart';
import '../providers/events_provider.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

const _kMeses = [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
];

Color _tipoColorForBrightness(Brightness brightness, String tipo) {
  final isDark = brightness == Brightness.dark;
  final colors = <String, Color>{
    'concierto': isDark ? AppColors.tierraDark : AppColors.tierraProfunda,
    'exposicion': isDark ? AppColors.oroDark : AppColors.oroAndino,
    'taller': isDark ? AppColors.indigoDark : AppColors.indigoNoche,
    'feria': isDark ? AppColors.selvaDark : AppColors.selvaAndina,
    'convocatoria': AppColors.error,
  };
  return colors[tipo] ??
      (isDark ? AppColors.textMutedDark : AppColors.textMutedLight);
}

Color _tipoColorFromContext(BuildContext context, String tipo) =>
    _tipoColorForBrightness(Theme.of(context).brightness, tipo);

String _twoDigits(int v) => v.toString().padLeft(2, '0');

// ─── Pantalla principal ──────────────────────────────────────────────────────

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  bool _isCalendarView = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _artistController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isCalendarView) {
        ref.read(eventsProvider.notifier).setMostrarPasados(true);
      } else {
        ref.read(eventsProvider.notifier).loadEvents();
      }
    });
  }

  @override
  void dispose() {
    _artistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsProvider);
    final role = ref.watch(currentUserRoleProvider).value;
    final canPublish = role == 'gestor' || role == 'admin';

    // ── Colores resueltos desde el tema ──────────────────────────────────────
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // AppBar usa el color de superficie primaria definido en el tema.
    // AppColors.obsidiana es el valor correcto tanto en light como en dark
    // porque el AppBar siempre tiene fondo oscuro en este diseño.
    // Sin embargo, usamos cs.surface / onSurface para máxima coherencia:
    const appBarBg = AppColors.obsidiana; // intencional (branding)
    const appBarFg = AppColors.oroClaro; // intencional (branding)

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        title: Text(
          'Agenda Cultural',
          style: AppTypography.displaySemiBold(color: appBarFg),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isCalendarView ? Icons.list : Icons.calendar_month,
              color: appBarFg,
            ),
            tooltip: _isCalendarView ? 'Ver como lista' : 'Ver como calendario',
            onPressed: () => setState(() => _isCalendarView = !_isCalendarView),
          ),
          if (canPublish)
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.oroClaro),
              tooltip: 'Publicar evento',
              onPressed: () => context.push('/events/new'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filtros ─────────────────────────────────────────────────────────
          _FilterSection(
            state: state,
            artistController: _artistController,
            onArtistChanged: (val) =>
                ref.read(eventsProvider.notifier).setFiltroArtista(val),
          ),
          // ── Cuerpo principal ────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: cs.primary,
              onRefresh: () async =>
                  ref.read(eventsProvider.notifier).loadEvents(),
              child: _isCalendarView
                  ? _CalendarBody(
                      state: state,
                      focusedDay: _focusedDay,
                      selectedDay: _selectedDay,
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                      onPageChanged: (focused) => _focusedDay = focused,
                    )
                  : _ListBody(state: state),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sección de Filtros ──────────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.state,
    required this.artistController,
    required this.onArtistChanged,
  });

  final EventsState state;
  final TextEditingController artistController;
  final ValueChanged<String> onArtistChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    // Color de fondo del input coherente con el tema
    final fillColor = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;

    return Column(
      children: [
        const _FilterChips(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: artistController,
            onChanged: onArtistChanged,
            style: AppTypography.bodySmall(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: 'Filtrar por artista...',
              hintStyle: AppTypography.bodySmall(color: textMuted),
              prefixIcon: Icon(Icons.person_search, size: 20, color: textMuted),
              filled: true,
              fillColor: fillColor,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventsProvider);
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Chip(
            label: 'Todos',
            selected: state.tipoFiltro == null,
            onTap: () => ref.read(eventsProvider.notifier).setTipoFiltro(null),
          ),
          ...EventTypes.all.map((t) {
            final isSelected = state.tipoFiltro == t;
            return _Chip(
              label: EventTypes.labels[t]!,
              selected: isSelected,
              onTap: () => ref
                  .read(eventsProvider.notifier)
                  .setTipoFiltro(isSelected ? null : t),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary : bgCard,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? cs.primary : border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption(
            color: selected ? cs.onPrimary : textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Vista de Calendario ─────────────────────────────────────────────────────

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({
    required this.state,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final EventsState state;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final OnDaySelected onDaySelected;
  final void Function(DateTime) onPageChanged;

  List<EventModel> _getEventsForDay(DateTime day) =>
      state.filteredEvents.where((e) => isSameDay(e.fecha, day)).toList();

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.events.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    // Fondo del encabezado del calendario igual que el AppBar (branding)
    const calHeaderBg = AppColors.obsidiana;
    const calHeaderFg = AppColors.oroClaro;

    final eventsForSelectedDay =
        selectedDay != null ? _getEventsForDay(selectedDay!) : <EventModel>[];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        TableCalendar<EventModel>(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 730)),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          onPageChanged: onPageChanged,
          calendarFormat: CalendarFormat.month,
          eventLoader: _getEventsForDay,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: AppTypography.labelSemiBold(color: calHeaderFg),
            decoration: const BoxDecoration(color: calHeaderBg),
            leftChevronIcon: const Icon(Icons.chevron_left, color: calHeaderFg),
            rightChevronIcon:
                const Icon(Icons.chevron_right, color: calHeaderFg),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            // Fondo de la fila de días de la semana coherente con el tema
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
            ),
            weekdayStyle: AppTypography.caption(color: textSecondary),
            weekendStyle: AppTypography.caption(color: textSecondary),
          ),
          calendarStyle: CalendarStyle(
            // Fondo general del cuerpo del calendario
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.primary,
                width: 2,
              ),
            ),
            todayTextStyle: AppTypography.bodyMedium(color: cs.primary),
            selectedDecoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: AppTypography.bodyMedium(color: cs.onPrimary),
            defaultTextStyle: AppTypography.bodyMedium(color: textPrimary),
            weekendTextStyle: AppTypography.bodyMedium(color: textPrimary),
            outsideTextStyle: AppTypography.bodyMedium(color: textMuted),
            disabledTextStyle: AppTypography.bodyMedium(color: textMuted),
            markerDecoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final events = _getEventsForDay(day);
              final isPast = day
                  .isBefore(DateTime.now().subtract(const Duration(days: 1)));
              return _buildDayCell(context, day, events, isPast: isPast);
            },
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: events
                    .take(3)
                    .map((e) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: _tipoColorFromContext(context, e.tipo),
                            shape: BoxShape.circle,
                          ),
                        ))
                    .toList(),
              );
            },
            singleMarkerBuilder: (context, day, event) {
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: _tipoColorFromContext(context, event.tipo),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        ),
        Divider(height: 1, color: dividerColor),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedDay == null
                    ? 'Selecciona un día'
                    : 'Eventos del ${selectedDay!.day} '
                        '${_kMeses[selectedDay!.month - 1]}',
                style: AppTypography.labelSemiBold(color: textPrimary),
              ),
              const SizedBox(height: 12),
              if (eventsForSelectedDay.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Sin eventos este día',
                      style: AppTypography.bodySmall(color: textMuted),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: eventsForSelectedDay.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _CompactEventCard(event: eventsForSelectedDay[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    List<EventModel> events, {
    required bool isPast,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: isPast ? 0.45 : 1.0,
            child: Text(
              '${day.day}',
              style: AppTypography.bodyMedium(
                color: isPast ? textMuted : textPrimary,
              ),
            ),
          ),
          if (events.any((e) => e.esDestacado))
            const Positioned(
              right: -4,
              top: -4,
              child: Icon(Icons.star, color: AppColors.oroAndino, size: 10),
            ),
        ],
      ),
    );
  }
}

// ─── Vista de Lista ──────────────────────────────────────────────────────────

class _ListBody extends ConsumerWidget {
  const _ListBody({required this.state});

  final EventsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: cs.primary),
      );
    }

    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              state.errorMessage ?? 'Ha ocurrido un error',
              style: AppTypography.bodyMedium(color: textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(eventsProvider.notifier).loadEvents(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final filteredEvents = state.filteredEvents;
    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, color: textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              'No hay eventos que coincidan\ncon los filtros',
              style: AppTypography.bodyMedium(color: textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _ListControlBar(state: state),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredEvents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _EventCard(event: filteredEvents[i]),
          ),
        ),
      ],
    );
  }
}

class _ListControlBar extends ConsumerWidget {
  const _ListControlBar({required this.state});

  final EventsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Text(
                '${state.filteredEvents.length} eventos',
                style: AppTypography.bodySmall(color: textMuted),
              ),
              const Spacer(),
              Text(
                'Incluir pasados',
                style: AppTypography.caption(color: textSecondary),
              ),
              Switch(
                value: state.mostrarPasados,
                activeThumbColor: cs.primary,
                onChanged: (_) =>
                    ref.read(eventsProvider.notifier).togglePasados(),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: dividerColor),
      ],
    );
  }
}

// ─── Cards ───────────────────────────────────────────────────────────────────

class _CompactEventCard extends StatelessWidget {
  const _CompactEventCard({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final color = _tipoColorFromContext(context, event.tipo);

    return InkWell(
      onTap: () => context.push('/events/${event.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.tipoLabel.toUpperCase(),
                        style: AppTypography.caption(color: color).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                      if (event.esDestacado) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star,
                            color: AppColors.oroAndino, size: 12),
                      ],
                    ],
                  ),
                  Text(
                    event.nombre,
                    style: AppTypography.labelSemiBold(color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_twoDigits(event.fecha.hour)}:'
                    '${_twoDigits(event.fecha.minute)} · ${event.lugar}',
                    style: AppTypography.caption(color: textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: textMuted),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final color = _tipoColorFromContext(context, event.tipo);
    final isPast = event.esPasado;

    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isPast ? bgSubtle : bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: event.esDestacado ? AppColors.oroAndino : border,
            width: event.esDestacado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _DateColumn(event: event, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BadgeRow(event: event, color: color),
                    const SizedBox(height: 6),
                    Text(
                      event.nombre,
                      style: AppTypography.labelSemiBold(
                        color: isPast ? textMuted : textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _MetaRow(
                        icon: Icons.location_on_outlined, text: event.lugar),
                    _MetaRow(
                      icon: Icons.access_time_outlined,
                      text:
                          '${_twoDigits(event.fecha.hour)}:${_twoDigits(event.fecha.minute)}',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right, color: textMuted, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateColumn extends StatelessWidget {
  const _DateColumn({required this.event, required this.color});

  final EventModel event;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final isPast = event.esPasado;
    final textColor = isPast ? textMuted : color;

    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isPast ? bgSubtle : color.withValues(alpha: 0.09),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          bottomLeft: Radius.circular(14),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${event.fecha.day}',
            style: AppTypography.displaySemiBold(color: textColor)
                .copyWith(fontSize: 22),
          ),
          Text(
            _kMeses[event.fecha.month - 1],
            style: AppTypography.caption(color: textColor),
          ),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.event, required this.color});

  final EventModel event;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        _SmallBadge(
          label: event.tipoLabel,
          bg: color.withValues(alpha: 0.12),
          fg: color,
        ),
        if (event.esDestacado) ...[
          const SizedBox(width: 6),
          _SmallBadge(
            label: '⭐ Destacado',
            bg: isDark
                ? AppColors.oroAndino.withValues(alpha: 0.18)
                : AppColors.oroPalido,
            fg: isDark ? AppColors.oroDark : AppColors.oroAndino,
          ),
        ],
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        label,
        style: AppTypography.caption(color: fg).copyWith(fontSize: 10),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: textMuted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption(color: textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
