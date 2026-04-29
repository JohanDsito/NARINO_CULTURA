import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../ai/data/ai_service.dart';
import '../../../artworks/domain/artwork_model.dart';
import '../../../../shared/widgets/artwork_card.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';

final _aiArtworkRecoProvider =
    FutureProvider.autoDispose<List<ArtworkModel>>((ref) async {
  return AiService().getArtworkRecommendations();
});

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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(context, ref),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(),
            _buildQuickAccess(context),
            _buildSectionHeader(
              title: 'Obras destacadas',
              subtitle: 'Descubre el arte de Nariño',
            ),
            _buildArtworkCards(),
            _buildForYouSection(ref),
            _buildSectionHeader(
              title: 'Próximos eventos',
              subtitle: 'Agenda cultural del departamento',
            ),
            _buildEventCards(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.tierraProfunda,
        onPressed: () => context.push('/chatbot'),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unread = unreadAsync.valueOrNull ?? 0;

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
            child: const Icon(
              Icons.landscape_outlined,
              color: AppColors.obsidiana,
              size: 16,
            ),
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
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.oroClaro,
              ),
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
                      style: AppTypography.caption(color: Colors.white)
                          .copyWith(fontSize: 9),
                    ),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.person_outline, color: AppColors.oroClaro),
          onPressed: () => context.go('/profile'),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(color: AppColors.obsidiana),
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
              color: AppColors.oroClaro.withAlpha(191),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    final items = [
      {
        'icon': Icons.palette_outlined,
        'label': 'Catálogo',
        'route': '/catalog',
        'color': AppColors.tierraProfunda,
      },
      {
        'icon': Icons.storefront_outlined,
        'label': 'Tienda',
        'route': '/marketplace',
        'color': AppColors.oroAndino,
      },
      {
        'icon': Icons.gavel_outlined,
        'label': 'Subastas',
        'route': '/auctions',
        'color': AppColors.indigoNoche,
      },
      {
        'icon': Icons.event_outlined,
        'label': 'Eventos',
        'route': '/events',
        'color': AppColors.selvaAndina,
      },
    ];

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
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final color = item['color'] as Color;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.go(item['route'] as String),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCardLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(31),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['label'] as String,
                      style: AppTypography.labelSemiBold(
                        color: AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      {required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.displaySemiBold(
                color: AppColors.textPrimaryLight),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style:
                AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkCards() {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _mockArtworks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = _mockArtworks[index];
          return Container(
            width: 220,
            decoration: BoxDecoration(
              color: AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 74,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.bgSubtleLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.textMutedLight.withAlpha(230),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item['title']!,
                  style: AppTypography.labelSemiBold(
                    color: AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item['artist']!,
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      item['price']!,
                      style: AppTypography.labelSemiBold(
                        color: AppColors.tierraProfunda,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.oroPalido,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Ver',
                        style:
                            AppTypography.caption(color: AppColors.obsidiana),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final event in _mockEvents) ...[
            _EventCard(
              title: event['title']!,
              date: event['date']!,
              place: event['place']!,
              type: event['type']!,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.title,
    required this.date,
    required this.place,
    required this.type,
  });

  final String title;
  final String date;
  final String place;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(14),
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
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelSemiBold(
                    color: AppColors.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.textMutedLight,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        date,
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: AppColors.textMutedLight,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        place,
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.indigoPalido,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              type,
              style: AppTypography.caption(color: AppColors.indigoNoche),
            ),
          ),
        ],
      ),
    );
  }
}

extension on HomeScreen {
  Widget _buildForYouSection(WidgetRef ref) {
    final asyncReco = ref.watch(_aiArtworkRecoProvider);
    return asyncReco.when(
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Para ti',
                    style: AppTypography.displaySemiBold(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recomendaciones basadas en tu actividad',
                    style: AppTypography.quoteItalic(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.tierraProfunda,
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        final items = list.take(6).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Para ti',
                    style: AppTypography.displaySemiBold(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recomendaciones basadas en tu actividad',
                    style: AppTypography.quoteItalic(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 170,
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
