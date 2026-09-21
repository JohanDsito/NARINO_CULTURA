import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/event_model.dart';
import '../../../domain/events_state.dart';
import 'compact_event_card.dart';
import 'event_helpers.dart';

class CalendarBody extends StatelessWidget {
  const CalendarBody({
    super.key,
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
                            color: tipoColorFromContext(context, e.tipo),
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
                  color: tipoColorFromContext(context, event.tipo),
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
                        '${kMeses[selectedDay!.month - 1]}',
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
                      CompactEventCard(event: eventsForSelectedDay[i]),
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
