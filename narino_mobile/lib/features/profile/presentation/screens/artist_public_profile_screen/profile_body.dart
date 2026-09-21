import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/app_avatar.dart';
import '../../../../artworks/presentation/providers/artwork_provider.dart';
import '../../../domain/profile_model.dart';
import 'artworks_section.dart';
import 'bio_section.dart';
import 'links_section.dart';
import 'section_divider.dart';
import 'stats_row.dart';

// ─── Cuerpo principal ─────────────────────────────────────────────────────────

class ProfileBody extends ConsumerWidget {
  const ProfileBody({
    super.key,
    required this.profile,
    required this.isFollowing,
    required this.loadingFollow,
    required this.onToggleFollow,
  });

  final ProfileModel profile;
  final bool isFollowing;
  final bool loadingFollow;
  final void Function(String id, bool follow) onToggleFollow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final worksAsync = ref.watch(artistArtworksProvider(profile.id));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: AppColors.obsidiana,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.oroClaro),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3D2410), AppColors.obsidiana],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Avatar con anillo dorado
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.oroClaro, AppColors.oroAndino],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: AppAvatar(
                          radius: 44,
                          url: profile.fotoUrl,
                          initials: profile.nombreArtistico,
                          backgroundColor: isDark
                              ? AppColors.bgSubtleDark
                              : AppColors.tierraPalida,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile.nombreArtistico,
                        style: AppTypography.displaySemiBold(
                          color: AppColors.oroClaro,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (profile.disciplina.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          profile.disciplina,
                          style: AppTypography.quoteItalic(
                            color: AppColors.oroClaro.withValues(alpha: 0.7),
                          ).copyWith(fontSize: 13),
                        ),
                      ],
                      if (profile.esVerificado) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified,
                                size: 14, color: AppColors.indigoClaro),
                            const SizedBox(width: 4),
                            Text(
                              'Verificado',
                              style: AppTypography.caption(
                                  color: AppColors.indigoClaro),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Contenido ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Estadísticas + Seguir ──────────────────────────────────
                StatsRow(
                  profile: profile,
                  isFollowing: isFollowing,
                  loadingFollow: loadingFollow,
                  onToggleFollow: onToggleFollow,
                ),

                // ── Biografía ─────────────────────────────────────────────
                if (profile.biografia != null &&
                    profile.biografia!.isNotEmpty) ...[
                  const SectionDivider(),
                  BioSection(bio: profile.biografia!),
                ],

                // ── Links (solo los que tienen valor) ────────────────────
                _buildLinks(context, profile, isDark),

                // ── Obras ─────────────────────────────────────────────────
                const SectionDivider(),
                ArtworksSection(slug: profile.id, worksAsync: worksAsync),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinks(
      BuildContext context, ProfileModel profile, bool isDark) {
    // Filtrar solo los links con valor no vacío
    final links = profile.redesSociales.entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList();

    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SectionDivider(),
        LinksSection(links: links),
      ],
    );
  }
}
