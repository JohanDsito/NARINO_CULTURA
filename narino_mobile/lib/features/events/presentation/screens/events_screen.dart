import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/events_state.dart';
import '../providers/events_provider.dart';
import 'events_screen/eventos_buscador.dart';
import 'events_screen/eventos_vista_calendario.dart';
import 'events_screen/eventos_vista_lista.dart';
import 'events_screen/tipo_evento_filtros.dart';

/// Agenda cultural (acento tomate): calendario o lista, búsqueda y tipos.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  bool _calendario = true;
  bool _verPasados = false;
  late DateTime _view = DateTime.now();
  DateTime _selected = soloDia(DateTime.now());
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = ref.read(eventsProvider).filtroArtista ?? '';
    // Se cargan todos (también pasados) y la vista decide qué mostrar:
    // antes, al cambiar de calendario a lista, se mezclaban eventos pasados.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = ref.read(eventsProvider.notifier);
      if (ref.read(eventsProvider).mostrarPasados) {
        n.loadEvents();
      } else {
        n.setMostrarPasados(true);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _buscar(String v) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300),
        () => ref.read(eventsProvider.notifier).setFiltroArtista(v.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final state = ref.watch(eventsProvider);
    final role = ref.watch(currentUserRoleProvider).valueOrNull;
    final canPublish = role == 'gestor' || role == 'admin' || role == 'artista';
    final top = MediaQuery.paddingOf(context).top + NcGlassHeader.contentHeight;
    final eventos = state.filteredEvents;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: NcGlassHeader(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AGENDA CULTURAL',
                style: AppTypography.caption(color: nc.eventos.ink)
                    .copyWith(letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text('Eventos',
                style: AppTypography.displaySemiBold(color: nc.textPrimary)),
          ],
        ),
        actions: [
          NcIconButton(
            icon: _calendario
                ? Icons.view_agenda_outlined
                : Icons.calendar_month_outlined,
            tooltip: _calendario ? 'Ver como lista' : 'Ver como calendario',
            onPressed: () => setState(() => _calendario = !_calendario),
          ),
          if (canPublish)
            NcIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Publicar evento',
              onPressed: () => context.push('/events/new'),
            ),
        ],
      ),
      body: RefreshIndicator(
        edgeOffset: top,
        onRefresh: () => ref.read(eventsProvider.notifier).loadEvents(),
        child: ListView(
          padding: EdgeInsets.fromLTRB(0, top + 14, 0, 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: EventosBuscador(
                controller: _searchCtrl,
                onChanged: _buscar,
                onClear: () {
                  _searchCtrl.clear();
                  _buscar('');
                },
              ),
            ),
            const SizedBox(height: 12),
            TipoEventoFiltros(
              selected: state.tipoFiltro,
              onSelect: (t) =>
                  ref.read(eventsProvider.notifier).setTipoFiltro(t),
            ),
            const SizedBox(height: 16),
            if (state.isLoading && state.events.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.status == EventsStatus.error && state.events.isEmpty)
              NcEmptyState(
                icon: Icons.cloud_off_rounded,
                accent: nc.tomateA,
                title: 'No pudimos cargar la agenda',
                message: state.errorMessage ?? 'Intenta de nuevo.',
                actionLabel: 'Reintentar',
                onAction: () => ref.read(eventsProvider.notifier).loadEvents(),
              )
            else if (_calendario)
              EventosVistaCalendario(
                eventos: eventos,
                view: _view,
                selected: _selected,
                onPrev: () => setState(
                    () => _view = DateTime(_view.year, _view.month - 1)),
                onNext: () => setState(
                    () => _view = DateTime(_view.year, _view.month + 1)),
                onSelect: (d) => setState(() => _selected = d),
              )
            else
              EventosVistaLista(
                eventos: eventos,
                verPasados: _verPasados,
                onTogglePasados: () =>
                    setState(() => _verPasados = !_verPasados),
                hayBusqueda:
                    _searchCtrl.text.isNotEmpty || state.tipoFiltro != null,
              ),
          ],
        ),
      ),
    );
  }
}
