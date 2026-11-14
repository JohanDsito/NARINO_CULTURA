import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/providers/user_role_provider.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/event_model.dart';
import '../../providers/events_provider.dart';
import '../../widgets/eventos_ui.dart';
import '../../../../../shared/widgets/dialogs/confirmar_accion.dart';
import 'event_info_tile.dart';
import 'evento_app_bar.dart';
import 'evento_etiquetas.dart';
import 'evento_mapa.dart';

const _eventBaseUrl = 'https://narinocultura.com/eventos';

/// Detalle de un evento: datos, mapa, compartir e inscripción.
class EventDetailView extends ConsumerStatefulWidget {
  const EventDetailView({super.key, required this.event});

  final EventModel event;

  @override
  ConsumerState<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends ConsumerState<EventDetailView> {
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
    final ok = await confirmarAccion(
      context,
      titulo: '¿Cancelar tu inscripción?',
      mensaje: 'Dejarás de recibir el recordatorio de este evento. Puedes '
          'volver a inscribirte cuando quieras.',
      cancelar: 'Mantenerla',
      confirmar: 'Sí, cancelar',
    );
    if (!ok || !mounted) return;
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
    final logueado = ref.watch(currentUserRoleProvider).valueOrNull != null;
    final coords = e.latitud != null && e.longitud != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          EventoAppBar(
            event: e,
            onCopiar: _copiar,
            onCompartir: _compartir,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList.list(children: [
              EventoEtiquetas(event: e),
              const SizedBox(height: 14),
              Semantics(
                header: true,
                child: Text(e.nombre,
                    style: AppTypography.displayBlack(color: nc.textPrimary)
                        .copyWith(fontSize: 28, height: 1.12)),
              ),
              const SizedBox(height: 20),
              EventInfoTile(
                icon: Icons.event_rounded,
                accent: nc.eventos,
                titulo: 'Cuándo',
                texto: fechaLarga(e),
              ),
              const SizedBox(height: 10),
              EventInfoTile(
                icon: Icons.place_outlined,
                accent: nc.naranjaA,
                titulo: 'Dónde',
                texto: e.lugar,
                accion: 'Abrir en el mapa',
                onAccion: _abrirMapa,
              ),
              if (e.artistasRelacionados.isNotEmpty) ...[
                const SizedBox(height: 10),
                EventInfoTile(
                  icon: Icons.groups_outlined,
                  accent: nc.musica,
                  titulo: 'Con',
                  texto: e.artistasRelacionados.join(', '),
                ),
              ],
              if ((e.descripcion ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 26),
                Text('Sobre el evento',
                    style:
                        AppTypography.displaySemiBold(color: nc.textPrimary)),
                const SizedBox(height: 10),
                Text(e.descripcion!.trim(),
                    style: AppTypography.bodyLarge(color: nc.textSecondary)
                        .copyWith(fontSize: 15)),
              ],
              if (coords) ...[
                const SizedBox(height: 26),
                EventoMapa(
                  latitud: e.latitud!,
                  longitud: e.longitud!,
                  onAbrir: _abrirMapa,
                ),
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
