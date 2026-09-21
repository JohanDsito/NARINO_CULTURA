import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../ai/data/ai_service.dart';
import '../../../artworks/data/artwork_repository.dart';
import '../../../artworks/domain/artwork_model.dart';
import '../../../events/data/events_repository.dart';
import '../../../events/domain/event_model.dart';
import 'home_screen/featured_artworks.dart';
import 'home_screen/for_you_section.dart';
import 'home_screen/home_app_bar.dart';
import 'home_screen/quick_access.dart';
import 'home_screen/quick_item.dart';
import 'home_screen/section_header.dart';
import 'home_screen/upcoming_events.dart';
import 'home_screen/welcome_banner.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final homeFeaturedArtworksProvider =
    FutureProvider.autoDispose.family<List<ArtworkModel>, int>(
  (ref, limit) async {
    final result =
        await ArtworkRepository().getCatalog(ordenarPor: 'relevancia');
    return result.artworks.take(limit).toList();
  },
);

final homeUpcomingEventsProvider =
    FutureProvider.autoDispose.family<List<EventModel>, int>(
  (ref, limit) async {
    final list = await EventsRepository().getEvents(mostrarPasados: false);
    final upcoming = list.where((e) => !e.esPasado).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    return upcoming.take(limit).toList();
  },
);

final homeAiArtworkRecommendationsProvider =
    FutureProvider.autoDispose.family<List<ArtworkModel>, int>(
  (ref, limit) async {
    final list = await AiService().getArtworkRecommendations();
    return list.take(limit).toList();
  },
);

// ─── Datos de fallback ────────────────────────────────────────────────────────

const mockArtworks = [
  {'title': 'Cóndor Andino', 'artist': 'María Torres', 'price': '\$320.000'},
  {'title': 'Volcán en Calma', 'artist': 'Luis Zambrano', 'price': '\$180.000'},
  {'title': 'Carnaval Eterno', 'artist': 'Ana Benavides', 'price': '\$540.000'},
  {'title': 'Selva Nariñense', 'artist': 'Carlos Díaz', 'price': '\$210.000'},
];

const mockEvents = [
  {
    'title': 'Exposición: Raíces',
    'date': '3 mayo · 6:00 PM',
    'place': 'Casa de la Cultura, Pasto',
    'type': 'Exposición',
  },
  {
    'title': 'Taller de Acuarela',
    'date': '10 mayo · 9:00 AM',
    'place': 'Centro Cultural Taminango',
    'type': 'Taller',
  },
  {
    'title': 'Feria Artesanal Nariño',
    'date': '17 mayo · 10:00 AM',
    'place': 'Parque Nariño, Pasto',
    'type': 'Feria',
  },
];

// ─── Accesos rápidos ──────────────────────────────────────────────────────────

const kQuickItems = [
  QuickItem(
    icon: Icons.palette_outlined,
    label: 'Catálogo',
    route: '/catalog',
    color: AppColors.tierraProfunda,
  ),
  QuickItem(
    icon: Icons.storefront_outlined,
    label: 'Tienda',
    route: '/marketplace',
    color: AppColors.oroAndino,
  ),
  QuickItem(
    icon: Icons.gavel_outlined,
    label: 'Subastas',
    route: '/auctions',
    color: AppColors.indigoNoche,
  ),
  QuickItem(
    icon: Icons.event_outlined,
    label: 'Eventos',
    route: '/events',
    color: AppColors.selvaAndina,
  ),
  QuickItem(
    icon: Icons.library_music_outlined,
    label: 'Músicos',
    route: '/musicians',
    color: AppColors.indigoClaro,
  ),
  QuickItem(
    icon: Icons.auto_awesome_outlined,
    label: 'Descubrir',
    route: '/music-discovery',
    color: AppColors.indigoClaro,
  ),
];

// ─── Helpers ──────────────────────────────────────────────────────────────────

String formatCOP(double value) {
  final n = value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  return '\$$n';
}

// ─── Pantalla principal ───────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: HomeAppBar(ref: ref),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WelcomeBanner(),
            const QuickAccess(),
            const SectionHeader(
              title: 'Obras destacadas',
              subtitle: 'Descubre el arte de Nariño',
            ),
            FeaturedArtworks(ref: ref),
            ForYouSection(ref: ref),
            const SectionHeader(
              title: 'Próximos eventos',
              subtitle: 'Agenda cultural del departamento',
            ),
            UpcomingEvents(ref: ref),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        tooltip: 'Asistente IA',
        onPressed: () => context.push('/chatbot'),
        child: Icon(
          Icons.chat_bubble_outline,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
