import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../providers/events_provider.dart';
import 'event_detail_screen/event_detail_view.dart';

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
          data: (event) => EventDetailView(event: event),
        );
  }
}
