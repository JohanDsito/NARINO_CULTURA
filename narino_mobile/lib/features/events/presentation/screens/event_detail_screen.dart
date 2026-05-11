import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/event_model.dart';
import '../providers/events_provider.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvent = ref.watch(eventDetailProvider(eventId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return asyncEvent.when(
      loading: () => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: cs.primary,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (e, _) => _ErrorScaffold(message: e.toString()),
      data: (event) => _EventBody(event: event),
    );
  }
}

// ─── Vista de error ───────────────────────────────────────────────────────────

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Evento',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 48,
                color: muted,
              ),
              const SizedBox(height: 14),
              Text(
                'No se pudo cargar el evento',
                style: AppTypography.bodyMedium(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: AppTypography.bodySmall(color: muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cuerpo del evento ────────────────────────────────────────────────────────

class _EventBody extends StatefulWidget {
  const _EventBody({required this.event});

  final EventModel event;

  @override
  State<_EventBody> createState() => _EventBodyState();
}

class _EventBodyState extends State<_EventBody> {
  static const _eventBaseUrl = 'https://narinocultura.com/eventos';

  late bool _estaSuscrito;
  bool _toggleLoading = false;

  @override
  void initState() {
    super.initState();
    _estaSuscrito = widget.event.estaSuscrito;
  }

  // ─── Acciones ─────────────────────────────────────────────────────────────

  Future<void> _copyLink() async {
    final url = '$_eventBaseUrl/${widget.event.id}';
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace copiado al portapapeles')),
      );
    }
  }

  Future<void> _openGoogleMaps() async {
    final place = widget.event.lugar.trim();
    if (place.isEmpty) {
      _showSnackBar('Este evento no tiene ubicación.');
      return;
    }

    Uri uri;
    if (widget.event.latitud != null && widget.event.longitud != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.event.latitud},${widget.event.longitud}',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(place)}',
      );
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar('No se pudo abrir Google Maps.');
    }
  }

  Future<void> _toggleRecordatorio() async {
    if (_toggleLoading) return;
    setState(() => _toggleLoading = true);
    try {
      final id = widget.event.id;
      if (_estaSuscrito) {
        await ApiClient.instance.dio.delete('/events/$id/subscribe/');
        if (mounted) setState(() => _estaSuscrito = false);
      } else {
        await ApiClient.instance.dio.post('/events/$id/subscribe/');
        if (mounted) setState(() => _estaSuscrito = true);
      }
    } catch (_) {
      _showSnackBar('No se pudo actualizar el recordatorio.');
    } finally {
      if (mounted) setState(() => _toggleLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final event = widget.event;
    final hasFlyerUrl = event.flyerUrl != null && event.flyerUrl!.isNotEmpty;
    final hasCoordinates = event.latitud != null && event.longitud != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── AppBar con imagen ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: hasFlyerUrl ? 260 : 120,
            pinned: true,
            backgroundColor: AppColors.obsidiana,
            foregroundColor: Colors.white,
            leading: const BackButton(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.link, color: Colors.white),
                tooltip: 'Copiar enlace',
                onPressed: _copyLink,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: hasFlyerUrl
                  ? _FlyerImage(url: event.flyerUrl!)
                  : const _FlyerPlaceholder(),
            ),
          ),

          // ── Contenido ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Badges
                  Row(
                    children: [
                      _TypePill(label: event.tipoLabel),
                      if (event.esDestacado) ...[
                        const SizedBox(width: 8),
                        const _FeaturedPill(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Título
                  Text(
                    event.nombre,
                    style: AppTypography.displayBold(
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Divider
                  const Divider(),
                  const SizedBox(height: 16),

                  // 5. Info del evento
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text: event.fechaFormateada,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: event.lugar,
                  ),
                  if (event.artistasRelacionados.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.people_outline,
                      text: event.artistasRelacionados.join(', '),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // 6. Mapa integrado
                  if (hasCoordinates) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              event.latitud!,
                              event.longitud!,
                            ),
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.narino_cultura.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    event.latitud!,
                                    event.longitud!,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_on,
                                    color: cs.primary,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© OpenStreetMap contributors',
                      style: AppTypography.caption(
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 7. Botón "Abrir en Google Maps" (Secundario)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.map_outlined),
                      label: Text(
                        'Abrir en Google Maps',
                        style: AppTypography.buttonText(
                          color: cs.primary,
                        ),
                      ),
                      onPressed: _openGoogleMaps,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 8. Divider
                  const Divider(),
                  const SizedBox(height: 20),

                  // 9. Descripción
                  if (event.descripcion != null &&
                      event.descripcion!.trim().isNotEmpty) ...[
                    Text(
                      event.descripcion!.trim(),
                      style: AppTypography.bodyMedium(
                        color: textSecondary,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 10. Botón de recordatorio
                  _ReminderButton(
                    subscribed: _estaSuscrito,
                    loading: _toggleLoading,
                    onPressed: _toggleRecordatorio,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Imagen del flyer ─────────────────────────────────────────────────────────

class _FlyerImage extends StatelessWidget {
  const _FlyerImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgSubtle =
            isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
        return Container(
          color: bgSubtle,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, __, ___) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgSubtle =
            isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
        final textMuted =
            isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
        return Container(
          color: bgSubtle,
          child: Icon(Icons.image_outlined, color: textMuted, size: 60),
        );
      },
    );
  }
}

class _FlyerPlaceholder extends StatelessWidget {
  const _FlyerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.obsidiana,
      child: const Center(
        child: Icon(Icons.event_outlined, color: AppColors.oroClaro, size: 64),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall(color: textSecondary),
          ),
        ),
      ],
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    final pillFg = isDark ? AppColors.tierraDark : AppColors.tierraProfunda;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTypography.caption(color: pillFg),
      ),
    );
  }
}

class _FeaturedPill extends StatelessWidget {
  const _FeaturedPill();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark ? AppColors.bgSubtleDark : AppColors.oroPalido;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '⭐ Destacado',
        style: AppTypography.caption(color: AppColors.oroAndino),
      ),
    );
  }
}

// ─── Botón de recordatorio ────────────────────────────────────────────────────

class _ReminderButton extends StatelessWidget {
  const _ReminderButton({
    required this.subscribed,
    required this.loading,
    required this.onPressed,
  });

  final bool subscribed;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: subscribed
              ? (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.bgSubtleDark
                  : AppColors.bgSubtleLight)
              : Theme.of(context).colorScheme.primary,
          foregroundColor: subscribed
              ? (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight)
              : Colors.white,
          elevation: subscribed ? 0 : 2,
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                subscribed
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_outlined,
                size: 20,
              ),
        label: Text(
          subscribed ? 'Cancelar recordatorio' : 'Recordarme',
          style: AppTypography.buttonText(),
        ),
      ),
    );
  }
}
