import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/event_model.dart';
import '../../domain/events_state.dart';
import '../providers/events_provider.dart';
import '../widgets/eventos_ui.dart';

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
              child: _Buscador(
                controller: _searchCtrl,
                onChanged: _buscar,
                onClear: () {
                  _searchCtrl.clear();
                  _buscar('');
                },
              ),
            ),
            const SizedBox(height: 12),
            _TipoChips(
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
              _VistaCalendario(
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
              _VistaLista(
                eventos: eventos,
                verPasados: _verPasados,
                onTogglePasados: () =>
                    setState(() => _verPasados = !_verPasados),
                hayBusqueda: _searchCtrl.text.isNotEmpty ||
                    state.tipoFiltro != null,
              ),
          ],
        ),
      ),
    );
  }
}

class _Buscador extends StatelessWidget {
  const _Buscador({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(99),
      borderSide: BorderSide(color: nc.border),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, lugar o tema',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar búsqueda',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              ),
        fillColor: nc.bgGlass,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: pill,
        enabledBorder: pill,
        focusedBorder: pill.copyWith(
            borderSide: BorderSide(color: nc.eventos.fill, width: 1.5)),
      ),
    );
  }
}

class _TipoChips extends StatelessWidget {
  const _TipoChips({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final opciones = <String?>[null, ...kTiposEvento];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: opciones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = opciones[i];
          final sel = selected == t;
          final a = t == null ? nc.eventos : tipoAccent(nc, t);
          final fg = sel ? a.onFill : nc.textPrimary;
          return Semantics(
            selected: sel,
            button: true,
            label: t == null ? 'Todos' : tipoNombre(t),
            excludeSemantics: true,
            child: NcPressable(
              onTap: () => onSelect(sel && t != null ? null : t),
              pressedScale: 0.94,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? a.fill : nc.bgGlass,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: sel ? a.fill : nc.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (t != null) ...[
                      Icon(tipoIcon(t), size: 16, color: sel ? fg : a.ink),
                      const SizedBox(width: 6),
                    ],
                    Text(t == null ? 'Todos' : tipoNombre(t),
                        style: AppTypography.labelMedium(color: fg)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VistaCalendario extends StatelessWidget {
  const _VistaCalendario({
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

class _VistaLista extends StatelessWidget {
  const _VistaLista({
    required this.eventos,
    required this.verPasados,
    required this.onTogglePasados,
    required this.hayBusqueda,
  });

  final List<EventModel> eventos;
  final bool verPasados;
  final VoidCallback onTogglePasados;
  final bool hayBusqueda;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final hoy = soloDia(DateTime.now());
    final semana = hoy.add(const Duration(days: 7));
    final proximos = eventos.where((e) => !e.esPasado).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    final pasados = eventos.where((e) => e.esPasado).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    final grupos = <(String, List<EventModel>)>[
      ('Hoy', proximos.where((e) => soloDia(e.fecha.toLocal()) == hoy).toList()),
      (
        'Esta semana',
        proximos.where((e) {
          final d = soloDia(e.fecha.toLocal());
          return d.isAfter(hoy) && d.isBefore(semana);
        }).toList()
      ),
      (
        'Más adelante',
        proximos
            .where((e) => !soloDia(e.fecha.toLocal()).isBefore(semana))
            .toList()
      ),
    ];

    if (proximos.isEmpty && (!verPasados || pasados.isEmpty)) {
      return Column(
        children: [
          NcEmptyState(
            icon: Icons.event_busy_outlined,
            accent: nc.eventos,
            title: hayBusqueda ? 'Nada con esa búsqueda' : 'No hay eventos próximos',
            message: hayBusqueda
                ? 'Prueba con otra palabra o quita el filtro de tipo.'
                : 'Pronto habrá conciertos, ferias y talleres en la agenda.',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          if (pasados.isNotEmpty)
            TextButton(
              onPressed: onTogglePasados,
              child: const Text('Ver eventos pasados'),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (titulo, lista) in grupos)
            if (lista.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 4),
                child: Text(titulo,
                    style: AppTypography.displaySemiBold(color: nc.textPrimary)),
              ),
              for (final e in lista)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EventoCard(event: e),
                ),
              const SizedBox(height: 8),
            ],
          if (pasados.isNotEmpty)
            Center(
              child: TextButton.icon(
                onPressed: onTogglePasados,
                icon: Icon(verPasados
                    ? Icons.expand_less_rounded
                    : Icons.history_rounded),
                label: Text(verPasados
                    ? 'Ocultar eventos pasados'
                    : 'Ver eventos pasados (${pasados.length})'),
              ),
            ),
          if (verPasados)
            for (final e in pasados)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EventoCard(event: e),
              ),
        ],
      ),
    );
  }
}
