import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/event_model.dart';
import '../providers/events_provider.dart';
import '../widgets/eventos_ui.dart';

const _eventBaseUrl = 'https://narinocultura.com/eventos';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    return ref.watch(eventDetailProvider(eventId)).when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Evento')),
            body: ListView(children: [
              NcEmptyState(
                icon: Icons.event_busy_outlined,
                accent: nc.tomateA,
                title: 'No pudimos abrir este evento',
                message: e.toString(),
                actionLabel: 'Reintentar',
                onAction: () => ref.invalidate(eventDetailProvider(eventId)),
              ),
            ]),
          ),
          data: (event) => _EventView(event: event),
        );
  }
}

class _EventView extends ConsumerStatefulWidget {
  const _EventView({required this.event});

  final EventModel event;

  @override
  ConsumerState<_EventView> createState() => _EventViewState();
}

class _EventViewState extends ConsumerState<_EventView> {
  late bool _inscrito = widget.event.estaSuscrito;
  bool _loading = false;

  String get _url => '$_eventBaseUrl/${widget.event.id}';

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _compartir() async {
    final e = widget.event;
    await Share.share('${e.nombre} — ${fechaLarga(e)} en ${e.lugar}.\n'
        'Míralo en Nariño Cultura: $_url');
  }

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: _url));
    if (mounted) _snack('Enlace copiado');
  }

  Future<void> _abrirMapa() async {
    final e = widget.event;
    final q = (e.latitud != null && e.longitud != null)
        ? '${e.latitud},${e.longitud}'
        : Uri.encodeComponent(e.lugar);
    final ok = await launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) _snack('No se pudo abrir el mapa.');
  }

  Future<void> _cancelar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar tu inscripción?'),
        content: const Text('Dejarás de recibir el recordatorio de este '
            'evento. Puedes volver a inscribirte cuando quieras.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Mantenerla')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(eventsRepositoryProvider)
          .unregisterFromEvent(widget.event.id);
      if (!mounted) return;
      setState(() => _inscrito = false);
      _snack('Cancelaste tu inscripción.');
    } catch (e) {
      final msg = e.toString();
      // Si ya no estaba inscrita, el estado real es "no inscrita".
      if (msg.toLowerCase().contains('no estás inscrito')) {
        if (mounted) setState(() => _inscrito = false);
      }
      _snack(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _inscribirme() async {
    if (_inscrito) return _cancelar();
    setState(() => _loading = true);
    try {
      await ref.read(eventsRepositoryProvider).registerToEvent(widget.event.id);
      if (!mounted) return;
      setState(() => _inscrito = true);
      HapticFeedback.mediumImpact();
      _snack('¡Listo! Te avisaremos antes del evento.');
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('ya estás inscrito')) {
        if (mounted) setState(() => _inscrito = true);
        _snack('Ya estabas inscrito en este evento.');
      } else {
        _snack(msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final e = widget.event;
    final accent = tipoAccent(nc, e.tipo);
    final logueado = ref.watch(currentUserRoleProvider).valueOrNull != null;
    final flyer = e.flyerUrl;
    final coords = e.latitud != null && e.longitud != null;

    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.tint, nc.tomateA.tint],
        ),
      ),
      child: Center(child: Icon(tipoIcon(e.tipo), size: 56, color: accent.ink)),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: nc.bg,
            surfaceTintColor: Colors.transparent,
            shape: const Border(),
            automaticallyImplyLeading: false,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: GlassCircleButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Volver',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            actions: [
              GlassCircleButton(
                icon: Icons.link_rounded,
                tooltip: 'Copiar enlace',
                onPressed: _copiar,
              ),
              const SizedBox(width: 8),
              GlassCircleButton(
                icon: Icons.ios_share_rounded,
                tooltip: 'Compartir',
                onPressed: _compartir,
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (flyer != null && flyer.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: flyer,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => fallback,
                      errorWidget: (_, __, ___) => fallback,
                    )
                  else
                    fallback,
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -1,
                    child: Container(
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: nc.bg,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28)),
                      ),
                      child: const NcSerpentina(width: 44),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList.list(children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  NcStatusPill(
                    label: tipoNombre(e.tipo),
                    accent: accent,
                    icon: tipoIcon(e.tipo),
                    filled: true,
                  ),
                  if (e.esDestacado)
                    NcStatusPill(
                        label: 'Destacado',
                        accent: nc.oroA,
                        icon: Icons.star_rounded),
                  if (e.esPasado)
                    NcStatusPill(label: 'Ya pasó', accent: nc.azulA),
                  if (!e.publicado)
                    NcStatusPill(label: 'Borrador', accent: nc.oroA),
                ],
              ),
              const SizedBox(height: 14),
              Semantics(
                header: true,
                child: Text(e.nombre,
                    style: AppTypography.displayBlack(color: nc.textPrimary)
                        .copyWith(fontSize: 28, height: 1.12)),
              ),
              const SizedBox(height: 20),
              _InfoTile(
                icon: Icons.event_rounded,
                accent: nc.eventos,
                titulo: 'Cuándo',
                texto: fechaLarga(e),
              ),
              const SizedBox(height: 10),
              _InfoTile(
                icon: Icons.place_outlined,
                accent: nc.naranjaA,
                titulo: 'Dónde',
                texto: e.lugar,
                accion: 'Abrir en el mapa',
                onAccion: _abrirMapa,
              ),
              if (e.artistasRelacionados.isNotEmpty) ...[
                const SizedBox(height: 10),
                _InfoTile(
                  icon: Icons.groups_outlined,
                  accent: nc.musica,
                  titulo: 'Con',
                  texto: e.artistasRelacionados.join(', '),
                ),
              ],
              if ((e.descripcion ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 26),
                Text('Sobre el evento',
                    style: AppTypography.displaySemiBold(color: nc.textPrimary)),
                const SizedBox(height: 10),
                Text(e.descripcion!.trim(),
                    style: AppTypography.bodyLarge(color: nc.textSecondary)
                        .copyWith(fontSize: 15)),
              ],
              if (coords) ...[
                const SizedBox(height: 26),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(e.latitud!, e.longitud!),
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none),
                        onTap: (_, __) => _abrirMapa(),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.narino_cultura.app',
                        ),
                        MarkerLayer(markers: [
                          Marker(
                            point: LatLng(e.latitud!, e.longitud!),
                            width: 44,
                            height: 44,
                            child: Icon(Icons.location_on_rounded,
                                size: 44, color: nc.eventos.fill),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('© OpenStreetMap',
                    style: AppTypography.caption(color: nc.textMuted)),
              ],
            ]),
          ),
        ],
      ),
      bottomNavigationBar: e.esPasado || !logueado
          ? null
          : NcGlassBottomBar(
              child: _inscrito
                  ? NcSecondaryButton(
                      label: _loading
                          ? 'Cancelando…'
                          : 'Inscrito · Cancelar inscripción',
                      icon: Icons.check_circle_rounded,
                      onPressed: _loading ? null : _cancelar,
                    )
                  : NcPrimaryButton(
                      label: 'Inscribirme y recibir recordatorio',
                      icon: Icons.notifications_active_outlined,
                      loading: _loading,
                      onPressed: _inscribirme,
                    ),
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.accent,
    required this.titulo,
    required this.texto,
    this.accion,
    this.onAccion,
  });

  final IconData icon;
  final NcAccent accent;
  final String titulo;
  final String texto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return NcCard(
      padding: const EdgeInsets.all(14),
      gradientBorder: false,
      onTap: onAccion,
      child: Row(
        children: [
          NcAccentIcon(icon: icon, accent: accent, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo.toUpperCase(),
                    style: AppTypography.caption(color: nc.textMuted)
                        .copyWith(letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text(texto,
                    style: AppTypography.labelSemiBold(color: nc.textPrimary)
                        .copyWith(fontSize: 15, height: 1.3)),
                if (accion != null) ...[
                  const SizedBox(height: 4),
                  Text(accion!,
                      style: AppTypography.labelMedium(color: nc.azul)
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
