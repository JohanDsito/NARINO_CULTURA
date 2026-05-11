import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../ai/data/ai_service.dart';
import '../../../artworks/data/artwork_repository.dart';
import '../../../artworks/domain/artwork_model.dart';
import '../../../../shared/widgets/artwork_card.dart';
import '../../../events/data/events_repository.dart';
import '../../../events/domain/event_model.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';

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

const _mockArtworks = [
  {'title': 'Cóndor Andino', 'artist': 'María Torres', 'price': '\$320.000'},
  {'title': 'Volcán en Calma', 'artist': 'Luis Zambrano', 'price': '\$180.000'},
  {'title': 'Carnaval Eterno', 'artist': 'Ana Benavides', 'price': '\$540.000'},
  {'title': 'Selva Nariñense', 'artist': 'Carlos Díaz', 'price': '\$210.000'},
];

const _mockEvents = [
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

class _QuickItem {
  const _QuickItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String route;
  final Color color;
}

const _kQuickItems = [
  _QuickItem(
    icon: Icons.palette_outlined,
    label: 'Catálogo',
    route: '/catalog',
    color: AppColors.tierraProfunda,
  ),
  _QuickItem(
    icon: Icons.storefront_outlined,
    label: 'Tienda',
    route: '/marketplace',
    color: AppColors.oroAndino,
  ),
  _QuickItem(
    icon: Icons.gavel_outlined,
    label: 'Subastas',
    route: '/auctions',
    color: AppColors.indigoNoche,
  ),
  _QuickItem(
    icon: Icons.event_outlined,
    label: 'Eventos',
    route: '/events',
    color: AppColors.selvaAndina,
  ),
];

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatCOP(double value) {
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
      appBar: _HomeAppBar(ref: ref),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _WelcomeBanner(),
            const _QuickAccess(),
            const _SectionHeader(
              title: 'Obras destacadas',
              subtitle: 'Descubre el arte de Nariño',
            ),
            _FeaturedArtworks(ref: ref),
            _ForYouSection(ref: ref),
            const _SectionHeader(
              title: 'Próximos eventos',
              subtitle: 'Agenda cultural del departamento',
            ),
            _UpcomingEvents(ref: ref),
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

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar({required this.ref});

  final WidgetRef ref;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return AppBar(
      backgroundColor: AppColors.obsidiana,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.oroAndino,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.landscape_outlined,
                color: AppColors.obsidiana, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            'Nariño Cultura',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.oroClaro,
            ),
          ),
        ],
      ),
      actions: [
        _NotificationBell(unread: unread),
        IconButton(
          icon: const Icon(Icons.person_outline, color: AppColors.oroClaro),
          onPressed: () => context.go('/profile'),
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: AppColors.oroClaro),
          onPressed: () => context.push('/notifications'),
        ),
        if (unread > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: AppTypography.caption(
                    color: Theme.of(context).colorScheme.onError,
                  ).copyWith(fontSize: 9),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Banner de bienvenida ─────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      color: AppColors.obsidiana,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola 👋',
            style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
          ),
          const SizedBox(height: 4),
          Text(
            'Explora el arte y la cultura de Nariño',
            style: AppTypography.quoteItalic(
              color: AppColors.oroClaro.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Acceso rápido ────────────────────────────────────────────────────────────

class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.9,
        ),
        itemCount: _kQuickItems.length,
        itemBuilder: (context, i) => _QuickTile(item: _kQuickItems[i]),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.item});

  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.go(item.route),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: AppTypography.labelSemiBold(color: textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header de sección ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.displaySemiBold(color: textPrimary),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: AppTypography.bodySmall(color: textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Obras destacadas ─────────────────────────────────────────────────────────

class _FeaturedArtworks extends StatelessWidget {
  const _FeaturedArtworks({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final asyncFeatured = ref.watch(homeFeaturedArtworksProvider(4));
    final items = asyncFeatured.valueOrNull;
    final useMock = items == null || items.isEmpty;
    final count = useMock ? _mockArtworks.length : items.length;

    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (useMock) {
            return _ArtworkCardMock(data: _mockArtworks[i]);
          }
          return _ArtworkCardReal(
            artwork: items[i],
            onTap: () => context.go('/artworks/${items[i].id}'),
          );
        },
      ),
    );
  }
}

class _ArtworkCardMock extends StatelessWidget {
  const _ArtworkCardMock({required this.data});

  final Map<String, String> data;

  @override
  Widget build(BuildContext context) {
    return _ArtworkCardShell(
      title: data['title']!,
      artist: data['artist']!,
      price: data['price']!,
      onTap: null,
    );
  }
}

class _ArtworkCardReal extends StatelessWidget {
  const _ArtworkCardReal({required this.artwork, required this.onTap});

  final ArtworkModel artwork;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ArtworkCardShell(
      title: artwork.titulo,
      artist: artwork.artistaNombre,
      price: artwork.precio == null
          ? 'Precio a consultar'
          : _formatCOP(artwork.precio!),
      onTap: onTap,
    );
  }
}

class _ArtworkCardShell extends StatelessWidget {
  const _ArtworkCardShell({
    required this.title,
    required this.artist,
    required this.price,
    required this.onTap,
  });

  final String title;
  final String artist;
  final String price;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final pillBg = isDark
        ? AppColors.oroAndino.withValues(alpha: 0.22)
        : AppColors.oroPalido;
    final pillFg = isDark ? cs.onSurface : AppColors.obsidiana;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder de imagen
            Container(
              height: 78,
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.image_outlined, color: textMuted, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTypography.labelSemiBold(color: textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              artist,
              style: AppTypography.bodySmall(color: textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    price,
                    style: AppTypography.labelSemiBold(color: cs.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Ver',
                    style: AppTypography.caption(color: pillFg),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sección "Para ti" ────────────────────────────────────────────────────────

class _ForYouSection extends StatelessWidget {
  const _ForYouSection({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final asyncReco = ref.watch(homeAiArtworkRecommendationsProvider(6));

    return asyncReco.when(
      loading: () => const _ForYouHeader(loading: true),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        final items = list.take(6).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ForYouHeader(loading: false),
            SizedBox(
              height: 184,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 160,
                  child: ArtworkCard(artwork: items[i], compact: true),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ForYouHeader extends StatelessWidget {
  const _ForYouHeader({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Para ti',
                  style: AppTypography.displaySemiBold(color: textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  'Recomendaciones basadas en tu actividad',
                  style: AppTypography.bodySmall(color: textSecondary),
                ),
              ],
            ),
          ),
          if (loading)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: cs.primary),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Próximos eventos ─────────────────────────────────────────────────────────

class _UpcomingEvents extends StatelessWidget {
  const _UpcomingEvents({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final asyncEvents = ref.watch(homeUpcomingEventsProvider(3));
    final items = asyncEvents.valueOrNull;
    final useMock = items == null || items.isEmpty;

    final eventCards = useMock
        ? _mockEvents.map((e) => _EventCard(
              title: e['title']!,
              date: e['date']!,
              place: e['place']!,
              type: e['type']!,
            ))
        : items.map((e) => _EventCard(
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

// ─── Tarjeta de evento ────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.title,
    required this.date,
    required this.place,
    required this.type,
    this.onTap,
  });

  final String title;
  final String date;
  final String place;
  final String type;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final typeBg = isDark
        ? AppColors.indigoNoche.withValues(alpha: 0.25)
        : AppColors.indigoPalido;
    final typeFg = isDark ? AppColors.indigoDark : AppColors.indigoNoche;
    final eventIconBg = isDark
        ? AppColors.selvaAndina.withValues(alpha: 0.22)
        : AppColors.selvaPalida;
    final eventIconFg = isDark ? AppColors.selvaDark : AppColors.selvaAndina;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: eventIconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event_outlined, color: eventIconFg, size: 22),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelSemiBold(color: textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _EventMeta(icon: Icons.schedule_outlined, text: date),
                  const SizedBox(height: 2),
                  _EventMeta(icon: Icons.place_outlined, text: place),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Badge de tipo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: typeBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                type,
                style: AppTypography.caption(color: typeFg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventMeta extends StatelessWidget {
  const _EventMeta({required this.icon, required this.text});

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
      children: [
        Icon(icon, size: 13, color: textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall(color: textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
