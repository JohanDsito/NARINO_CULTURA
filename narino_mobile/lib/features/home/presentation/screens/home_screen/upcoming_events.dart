import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../home_screen.dart';
import 'event_card.dart';

// ─── Próximos eventos ─────────────────────────────────────────────────────────

class UpcomingEvents extends StatelessWidget {
  const UpcomingEvents({required this.ref, super.key});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final asyncEvents = ref.watch(homeUpcomingEventsProvider(3));
    final items = asyncEvents.valueOrNull;
    final useMock = items == null || items.isEmpty;

    final eventCards = useMock
        ? mockEvents.map((e) => EventCard(
              title: e['title']!,
              date: e['date']!,
              place: e['place']!,
              type: e['type']!,
            ))
        : items.map((e) => EventCard(
              title: e.nombre,
              date: e.fechaFormateada,
              place: e.lugar,
              type: e.tipoLabel,
              onTap: () => context.push('/events/${e.id}'),
            ));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: eventCards
            .expand((card) => [card, const SizedBox(height: 10)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}
