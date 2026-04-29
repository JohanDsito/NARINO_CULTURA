import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/event_model.dart';
import '../providers/events_provider.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvent = ref.watch(eventDetailProvider(eventId));

    return asyncEvent.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.tierraProfunda),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bgLight,
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
            child: Text(
              'No se pudo cargar el evento',
              style: AppTypography.bodySmall(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (event) => _Body(event: event),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.event});

  final EventModel event;

  static const String _eventBaseUrl = 'https://narinocultura.com/eventos';

  Future<void> _copyLink(BuildContext context) async {
    final url = '$_eventBaseUrl/${event.id}';
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace copiado al portapapeles')),
      );
    }
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final place = event.lugar.trim();
    if (place.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este evento no tiene ubicación.')),
        );
      }
      return;
    }

    final q = Uri.encodeComponent(place);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight:
                (event.flyerUrl != null && event.flyerUrl!.isNotEmpty)
                    ? 250
                    : 120,
            pinned: true,
            backgroundColor: AppColors.obsidiana,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.link, color: Colors.white),
                onPressed: () => _copyLink(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: (event.flyerUrl != null && event.flyerUrl!.isNotEmpty)
                  ? Image.network(
                      event.flyerUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.obsidiana),
                    )
                  : Container(
                      color: AppColors.obsidiana,
                      child: const Icon(
                        Icons.event_outlined,
                        color: AppColors.oroClaro,
                        size: 64,
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tierraPalida,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      event.tipoLabel,
                      style: AppTypography.caption(
                        color: AppColors.tierraProfunda,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.nombre,
                    style: AppTypography.displayBold(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    event.fechaFormateada,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.location_on_outlined, event.lugar),
                  if (event.artistasRelacionados.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.people_outline,
                      event.artistasRelacionados.join(', '),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 16),
                  if (event.descripcion != null &&
                      event.descripcion!.trim().isNotEmpty) ...[
                    Text(
                      'Sobre el evento',
                      style: AppTypography.labelSemiBold(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.descripcion!.trim(),
                      style: AppTypography.bodyMedium(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.map_outlined),
                      label: Text(
                        'Ver en Google Maps',
                        style: AppTypography.buttonText(color: Colors.white),
                      ),
                      onPressed: () => _openGoogleMaps(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMutedLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
          ),
        ),
      ],
    );
  }
}
