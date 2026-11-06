import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/design/design.dart';
import '../../../ai/data/ai_service.dart';
import '../../../artworks/data/artwork_repository.dart';
import '../../../artworks/domain/artwork_model.dart';
import '../../../events/data/events_repository.dart';
import '../../../events/domain/event_model.dart';
import 'home_screen/agenda_section.dart';
import 'home_screen/disciplines_carousel.dart';
import 'home_screen/featured_strip.dart';
import 'home_screen/hero_section.dart';
import 'home_screen/home_header_actions.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final homeFeaturedArtworksProvider =
    FutureProvider.autoDispose.family<List<ArtworkModel>, int>(
  (ref, limit) async {
    final result =
        await ArtworkRepository().getCatalog(ordenarPor: 'relevancia');
    return result.artworks.take(limit).toList();
  },
);

/// Próximos eventos ordenados por fecha (la agenda usa hasta [limit]).
final homeUpcomingEventsProvider =
    FutureProvider.autoDispose.family<List<EventModel>, int>(
  (ref, limit) async {
    final list = await EventsRepository().getEvents(mostrarPasados: false);
    final upcoming = list.where((e) => !e.esPasado).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    return upcoming.take(limit).toList();
  },
);

/// Recomendaciones IA. El backend aún no expone `/ai/recommendations/`;
/// se conserva para cuando exista.
final homeAiArtworkRecommendationsProvider =
    FutureProvider.autoDispose.family<List<ArtworkModel>, int>(
  (ref, limit) async {
    final list = await AiService().getArtworkRecommendations();
    return list.take(limit).toList();
  },
);

// ─── Helpers ──────────────────────────────────────────────────────────────────

String formatCOP(double value) {
  final n = value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  return '\$$n';
}

// ─── Pantalla principal ───────────────────────────────────────────────────────

/// Inicio (`narino_cultura_movil_2_inicio.html`): hero, disciplinas en
/// carrusel, obras destacadas y agenda con calendario, sobre el fondo carnaval
/// que pinta el shell.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _agendaKey = GlobalKey();

  void _scrollToAgenda() {
    final ctx = _agendaKey.currentContext;
    if (ctx == null) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    Scrollable.ensureVisible(
      ctx,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 600),
      curve: kNcEase,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      alignment: 0.05,
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(homeFeaturedArtworksProvider);
    ref.invalidate(homeUpcomingEventsProvider);
    await Future.wait([
      ref.read(homeFeaturedArtworksProvider(kHomeFeaturedLimit).future),
      ref.read(homeUpcomingEventsProvider(kHomeAgendaLimit).future),
    ].map((f) => f.catchError((_) => const <Never>[])));
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    const headerHeight = NcGlassHeader.contentHeight;

    return Scaffold(
      // Transparente: el fondo carnaval lo pinta el shell.
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const NcGlassHeader(actions: homeHeaderActions),
      body: RefreshIndicator(
        edgeOffset: topInset + headerHeight,
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.only(top: topInset + headerHeight + 28, bottom: 32),
          children: [
            HeroSection(onSecondaryFallback: _scrollToAgenda),
            const SizedBox(height: 44),
            const DisciplinesCarousel(),
            const SizedBox(height: 44),
            const FeaturedStrip(),
            KeyedSubtree(key: _agendaKey, child: const AgendaSection()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home-chatbot',
        tooltip: 'Asistente IA',
        onPressed: () => context.push('/chatbot'),
        child: const Icon(Icons.auto_awesome_outlined),
      ),
    );
  }
}
