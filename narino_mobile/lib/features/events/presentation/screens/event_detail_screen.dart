import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/events_provider.dart';
import 'event_detail_screen/error_scaffold.dart';
import 'event_detail_screen/event_body.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

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
      error: (e, _) => ErrorScaffold(message: e.toString()),
      data: (event) => EventBody(event: event),
    );
  }
}
