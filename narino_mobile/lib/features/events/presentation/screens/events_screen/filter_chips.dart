import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/event_model.dart';
import '../../providers/events_provider.dart';
import 'chip.dart';

class FilterChips extends ConsumerWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventsProvider);
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          EventChip(
            label: 'Todos',
            selected: state.tipoFiltro == null,
            onTap: () => ref.read(eventsProvider.notifier).setTipoFiltro(null),
          ),
          ...EventTypes.all.map((t) {
            final isSelected = state.tipoFiltro == t;
            return EventChip(
              label: EventTypes.labels[t]!,
              selected: isSelected,
              onTap: () => ref
                  .read(eventsProvider.notifier)
                  .setTipoFiltro(isSelected ? null : t),
            );
          }),
        ],
      ),
    );
  }
}
