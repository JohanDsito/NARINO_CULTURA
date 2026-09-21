import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/events_provider.dart';
import 'events_screen/calendar_body.dart';
import 'events_screen/filter_section.dart';
import 'events_screen/list_body.dart';

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
          FilterSection(
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
                  ? CalendarBody(
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
                  : EventListBody(state: state),
            ),
          ),
        ],
      ),
    );
  }
}
