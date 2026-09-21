import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/events_repository.dart';
import '../../../domain/event_model.dart';
import 'featured_pill.dart';
import 'flyer_image.dart';
import 'flyer_placeholder.dart';
import 'info_row.dart';
import 'reminder_button.dart';
import 'type_pill.dart';

// ─── Cuerpo del evento ────────────────────────────────────────────────────────

class EventBody extends StatefulWidget {
  const EventBody({super.key, required this.event});

  final EventModel event;

  @override
  State<EventBody> createState() => _EventBodyState();
}

class _EventBodyState extends State<EventBody> {
  static const _eventBaseUrl = 'https://narinocultura.com/eventos';
  final _eventsRepo = EventsRepository();

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
        await _eventsRepo.unregisterFromEvent(id);
        if (mounted) setState(() => _estaSuscrito = false);
      } else {
        await _eventsRepo.registerToEvent(id);
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
                  ? FlyerImage(url: event.flyerUrl!)
                  : const FlyerPlaceholder(),
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
                      TypePill(label: event.tipoLabel),
                      if (event.esDestacado) ...[
                        const SizedBox(width: 8),
                        const FeaturedPill(),
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
                  InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text: event.fechaFormateada,
                  ),
                  const SizedBox(height: 10),
                  InfoRow(
                    icon: Icons.location_on_outlined,
                    text: event.lugar,
                  ),
                  if (event.artistasRelacionados.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    InfoRow(
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
                  ReminderButton(
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
