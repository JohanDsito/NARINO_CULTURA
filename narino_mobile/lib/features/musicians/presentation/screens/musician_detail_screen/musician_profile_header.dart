import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/providers/user_role_provider.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/musician_model.dart';
import '../../providers/musician_provider.dart';
import '../../widgets/musica_ui.dart';
import 'musician_reviews_tab.dart';
import 'musician_stat.dart';
import 'musician_tabs_delegate.dart';
import 'musician_works_tab.dart';

class MusicianProfileHeader extends ConsumerWidget {
  const MusicianProfileHeader({super.key, required this.musician});

  final MusicianModel musician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final m = musician;
    final seguidores = seguidoresVisibles(m, ref.watch(seguidosProvider));
    final miSlug = ref.watch(myMusicianSlugProvider).valueOrNull;
    final esMio = miSlug != null && miSlug == m.slug;
    final logueado = ref.watch(currentUserRoleProvider).valueOrNull != null;
    final detalle = [
      if (formatoAgrupacion(m.aggregationType).isNotEmpty)
        formatoAgrupacion(m.aggregationType),
      if ((m.city ?? '').isNotEmpty) m.city!,
    ].join(' · ');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: 170,
              pinned: true,
              backgroundColor: nc.bg,
              surfaceTintColor: Colors.transparent,
              shape: const Border(),
              automaticallyImplyLeading: false,
              leadingWidth: 64,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Center(
                  child: GlassCircleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Volver',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    PortadaMusical(
                        url: m.coverUrl, icon: Icons.graphic_eq_rounded),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x33000000), Color(0x00000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -1,
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: nc.bg,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Sin desplazar hacia arriba: la barra fija lo recortaba.
                        MusicoAvatar(musician: m, radius: 38),
                        const Spacer(),
                        if (!esMio) SeguirButton(musician: m),
                        if (esMio)
                          NcSecondaryButton(
                            label: 'Subir obra',
                            icon: Icons.add_rounded,
                            expand: false,
                            onPressed: () =>
                                context.push('/musicians/works/publish'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Flexible(
                          child: Text(m.name,
                              style: AppTypography.displayBlack(
                                      color: nc.textPrimary)
                                  .copyWith(fontSize: 28)),
                        ),
                        if (m.isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified_rounded,
                              color: nc.musica.ink, size: 22),
                        ],
                      ],
                    ),
                    if (detalle.isNotEmpty)
                      Text(detalle,
                          style: AppTypography.bodyMedium(
                              color: nc.textSecondary)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        MusicianStat(valor: '$seguidores', label: 'seguidores'),
                        MusicianStat(
                            valor: m.reviewsCount > 0
                                ? m.averageRating.toStringAsFixed(1)
                                : '—',
                            label: 'calificación',
                            estrella: m.reviewsCount > 0),
                        MusicianStat(
                            valor: '${m.reviewsCount}', label: 'reseñas'),
                      ],
                    ),
                    if ((m.bio ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(m.bio!.trim(),
                          style: AppTypography.bodyMedium(
                              color: nc.textSecondary)),
                    ],
                    if (m.genres.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final g in m.genres)
                            NcStatusPill(label: g, accent: nc.musica),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SliverPersistentHeader(
                pinned: true, delegate: MusicianTabsDelegate()),
          ],
          body: TabBarView(
            children: [
              MusicianWorksTab(slug: m.slug),
              MusicianReviewsTab(musician: m, puedeResenar: logueado && !esMio),
            ],
          ),
        ),
      ),
    );
  }
}
