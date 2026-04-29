import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../ai/data/ai_service.dart';
import '../../domain/event_model.dart';
import '../../domain/events_state.dart';
import '../providers/events_provider.dart';

final _aiEventRecoProvider =
    FutureProvider.autoDispose<List<EventModel>>((ref) async {
  return AiService().getEventRecommendations();
});

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventsProvider.notifier).loadEvents();
    });
  }

  Color _tipoColor(String tipo) {
    const colors = {
      'concierto': AppColors.tierraProfunda,
      'exposicion': AppColors.oroAndino,
      'taller': AppColors.indigoNoche,
      'feria': AppColors.selvaAndina,
      'convocatoria': AppColors.error,
    };
    return colors[tipo] ?? AppColors.textMutedLight;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Agenda Cultural',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro)
              .copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.add_circle_outline, color: AppColors.oroClaro),
            onPressed: () => context.push('/events/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          _RecommendedSection(
            asyncEvents: ref.watch(_aiEventRecoProvider),
            onOpen: (id) => context.push('/events/$id'),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildChip(
                  'Todos',
                  state.tipoFiltro == null,
                  () => ref.read(eventsProvider.notifier).setTipoFiltro(null),
                ),
                ...EventTypes.all.map(
                  (t) => _buildChip(
                    EventTypes.labels[t]!,
                    state.tipoFiltro == t,
                    () => ref.read(eventsProvider.notifier).setTipoFiltro(
                          state.tipoFiltro == t ? null : t,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${state.events.length} eventos',
                  style:
                      AppTypography.bodySmall(color: AppColors.textMutedLight),
                ),
                const Spacer(),
                Text(
                  'Incluir pasados',
                  style: AppTypography.caption(
                      color: AppColors.textSecondaryLight),
                ),
                Switch(
                  value: state.mostrarPasados,
                  activeThumbColor: AppColors.tierraProfunda,
                  onChanged: (_) =>
                      ref.read(eventsProvider.notifier).togglePasados(),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(EventsState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.tierraProfunda),
      );
    }
    if (state.hasError) {
      return _ErrorBanner(
        message: state.errorMessage!,
        onRetry: () => ref.read(eventsProvider.notifier).loadEvents(),
      );
    }
    if (state.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_outlined,
              color: AppColors.textMutedLight,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay eventos',
              style: AppTypography.displaySemiBold(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: state.events.length,
      itemBuilder: (_, i) => _buildEventCard(context, state.events[i]),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    final color = _tipoColor(event.tipo);
    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        decoration: BoxDecoration(
          color:
              event.esPasado ? AppColors.bgSubtleLight : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                event.esDestacado ? AppColors.oroAndino : AppColors.borderLight,
            width: event.esDestacado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: event.esPasado
                    ? AppColors.bgSubtleLight
                    : color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${event.fecha.day}',
                    style: AppTypography.displaySemiBold(
                      color: event.esPasado ? AppColors.textMutedLight : color,
                    ).copyWith(fontSize: 22),
                  ),
                  Text(
                    [
                      'Ene',
                      'Feb',
                      'Mar',
                      'Abr',
                      'May',
                      'Jun',
                      'Jul',
                      'Ago',
                      'Sep',
                      'Oct',
                      'Nov',
                      'Dic'
                    ][event.fecha.month - 1],
                    style: AppTypography.caption(
                      color: event.esPasado ? AppColors.textMutedLight : color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            event.tipoLabel,
                            style: AppTypography.caption(color: color)
                                .copyWith(fontSize: 10),
                          ),
                        ),
                        if (event.esDestacado) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.oroPalido,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '⭐ Destacado',
                              style: AppTypography.caption(
                                      color: AppColors.oroAndino)
                                  .copyWith(fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.nombre,
                      style: AppTypography.labelSemiBold(
                        color: event.esPasado
                            ? AppColors.textMutedLight
                            : AppColors.textPrimaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '📍 ${event.lugar}',
                      style: AppTypography.caption(
                          color: AppColors.textMutedLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '🕐 ${event.fecha.hour.toString().padLeft(2, '0')}:${event.fecha.minute.toString().padLeft(2, '0')}',
                      style: AppTypography.caption(
                          color: AppColors.textMutedLight),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppColors.textMutedLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.tierraProfunda : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.tierraProfunda : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption(
            color: selected ? Colors.white : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

class _RecommendedSection extends StatelessWidget {
  const _RecommendedSection({required this.asyncEvents, required this.onOpen});

  final AsyncValue<List<EventModel>> asyncEvents;
  final void Function(int id) onOpen;

  @override
  Widget build(BuildContext context) {
    return asyncEvents.when(
      loading: () => const SizedBox(height: 0),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        final items = list.take(3).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(
                '✨ Recomendados para ti',
                style: AppTypography.displaySemiBold(
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            SizedBox(
              height: 132,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _RecommendedEventCard(
                  event: items[i],
                  onTap: () => onOpen(items[i].id),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecommendedEventCard extends StatelessWidget {
  const _RecommendedEventCard({required this.event, required this.onTap});

  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String two(int v) => v.toString().padLeft(2, '0');
    final time = '${two(event.fecha.hour)}:${two(event.fecha.minute)}';

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.selvaPalida,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_outlined,
                  color: AppColors.selvaAndina,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.nombre,
                      style: AppTypography.labelSemiBold(
                        color: AppColors.textPrimaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '📍 ${event.lugar}',
                      style: AppTypography.caption(
                        color: AppColors.textMutedLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '🕐 $time',
                      style: AppTypography.caption(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMutedLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 44),
              const SizedBox(height: 10),
              Text(
                message,
                style: AppTypography.bodyMedium(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tierraProfunda,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Reintentar',
                    style: AppTypography.labelSemiBold(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
