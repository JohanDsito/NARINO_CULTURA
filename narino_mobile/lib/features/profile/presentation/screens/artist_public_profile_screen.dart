import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../artworks/domain/artwork_model.dart';
import '../../../artworks/presentation/providers/artwork_provider.dart';
import '../../domain/profile_model.dart';
import '../providers/profile_provider.dart';

class ArtistPublicProfileScreen extends ConsumerStatefulWidget {
  final String artistId;
  const ArtistPublicProfileScreen({super.key, required this.artistId});

  @override
  ConsumerState<ArtistPublicProfileScreen> createState() =>
      _ArtistPublicProfileScreenState();
}

class _ArtistPublicProfileScreenState
    extends ConsumerState<ArtistPublicProfileScreen> {
  bool _isFollowing = false;
  bool _loadingFollow = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(artistProfileProvider(widget.artistId));

    return profileAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.obsidiana,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.oroClaro),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.indigoClaro),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.obsidiana,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.oroClaro),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_off_outlined,
                    size: 56, color: AppColors.indigoClaro),
                const SizedBox(height: 16),
                Text(
                  'No se pudo cargar el perfil',
                  style: AppTypography.bodyMedium(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      data: (profile) {
        if (!_loadingFollow) _isFollowing = profile.esSeguido;
        return _ProfileBody(
          profile: profile,
          isFollowing: _isFollowing,
          loadingFollow: _loadingFollow,
          onToggleFollow: _toggleFollow,
        );
      },
    );
  }

  Future<void> _toggleFollow(String profileId, bool follow) async {
    setState(() => _loadingFollow = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      if (follow) {
        await repo.followArtist(profileId);
      } else {
        await repo.unfollowArtist(profileId);
      }
      setState(() {
        _isFollowing = follow;
        _loadingFollow = false;
      });
      ref.invalidate(artistProfileProvider(profileId));
      ref.invalidate(myFollowingProvider);
    } catch (_) {
      setState(() => _loadingFollow = false);
    }
  }
}

// ─── Cuerpo principal ─────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({
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
                _StatsRow(
                  profile: profile,
                  isFollowing: isFollowing,
                  loadingFollow: loadingFollow,
                  onToggleFollow: onToggleFollow,
                ),

                // ── Biografía ─────────────────────────────────────────────
                if (profile.biografia != null &&
                    profile.biografia!.isNotEmpty) ...[
                  _SectionDivider(),
                  _BioSection(bio: profile.biografia!),
                ],

                // ── Links (solo los que tienen valor) ────────────────────
                _buildLinks(context, profile, isDark),

                // ── Obras ─────────────────────────────────────────────────
                _SectionDivider(),
                _ArtworksSection(slug: profile.id, worksAsync: worksAsync),

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
        _SectionDivider(),
        _LinksSection(links: links),
      ],
    );
  }
}

// ─── Estadísticas + botón Seguir ─────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          _StatItem(
              value: '${profile.seguidores}',
              label: 'Seguidores',
              textPrimary: textPrimary,
              textMuted: textMuted),
          const SizedBox(width: 4),
          Container(width: 1, height: 28, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(width: 16),
          _StatItem(
              value: '${profile.totalObras}',
              label: 'Obras',
              textPrimary: textPrimary,
              textMuted: textMuted),
          const Spacer(),
          SizedBox(
            height: 38,
            child: isFollowing
                ? OutlinedButton(
                    onPressed: loadingFollow
                        ? null
                        : () => onToggleFollow(profile.id, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: Text('Siguiendo',
                        style:
                            AppTypography.labelMedium(color: cs.primary)),
                  )
                : ElevatedButton(
                    onPressed: loadingFollow
                        ? null
                        : () => onToggleFollow(profile.id, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigoClaro,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: loadingFollow
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : Text('Seguir',
                            style: AppTypography.labelMedium(
                                color: Colors.white)),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.textPrimary,
    required this.textMuted,
  });

  final String value;
  final String label;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTypography.displaySemiBold(color: textPrimary)
                .copyWith(fontSize: 20)),
        Text(label, style: AppTypography.caption(color: textMuted)),
      ],
    );
  }
}

// ─── Biografía ────────────────────────────────────────────────────────────────

class _BioSection extends StatelessWidget {
  const _BioSection({required this.bio});

  final String bio;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Text(
        bio,
        style: AppTypography.quoteItalic(color: textSecondary)
            .copyWith(fontSize: 14, height: 1.55),
      ),
    );
  }
}

// ─── Links ────────────────────────────────────────────────────────────────────

class _LinksSection extends StatelessWidget {
  const _LinksSection({required this.links});

  final List<MapEntry<String, String>> links;

  static const _platforms = <String, (IconData, String, Color)>{
    'instagram': (Icons.camera_alt_outlined, 'Instagram', Color(0xFFE1306C)),
    'facebook': (Icons.facebook_outlined, 'Facebook', Color(0xFF1877F2)),
    'tiktok': (Icons.music_note_outlined, 'TikTok', Color(0xFF69C9D0)),
    'website': (Icons.language_outlined, 'Sitio web', AppColors.indigoClaro),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final bgCard = isDark ? AppColors.bgCardDark : AppColors.bgCardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Redes y enlaces',
              style: AppTypography.labelSemiBold(color: textPrimary)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Column(
              children: links
                  .expand<Widget>((e) => [
                        _LinkRow(
                            platform: e.key,
                            url: e.value,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            platforms: _platforms),
                        Divider(height: 1, indent: 56, color: border),
                      ])
                  .toList()
                ..removeLast(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.platform,
    required this.url,
    required this.textPrimary,
    required this.textMuted,
    required this.platforms,
  });

  final String platform;
  final String url;
  final Color textPrimary;
  final Color textMuted;
  final Map<String, (IconData, String, Color)> platforms;

  String get _displayUrl {
    var u = url;
    if (u.startsWith('https://')) u = u.substring(8);
    if (u.startsWith('http://')) u = u.substring(7);
    if (u.startsWith('www.')) u = u.substring(4);
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u.length > 36 ? '${u.substring(0, 33)}…' : u;
  }

  @override
  Widget build(BuildContext context) {
    final (icon, name, color) = platforms[platform.toLowerCase()] ??
        (Icons.link_outlined, platform, AppColors.indigoClaro);

    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          AppTypography.labelSemiBold(color: textPrimary)),
                  Text(_displayUrl,
                      style: AppTypography.caption(color: textMuted)),
                ],
              ),
            ),
            Icon(Icons.open_in_new_outlined, size: 15, color: textMuted),
          ],
        ),
      ),
    );
  }
}

// ─── Obras del artista ────────────────────────────────────────────────────────

class _ArtworksSection extends StatelessWidget {
  const _ArtworksSection(
      {required this.slug, required this.worksAsync});

  final String slug;
  final AsyncValue<List<ArtworkModel>> worksAsync;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Obras',
              style: AppTypography.displaySemiBold(color: textPrimary)
                  .copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          worksAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(
                    color: AppColors.indigoClaro, strokeWidth: 2),
              ),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('No se pudieron cargar las obras.',
                  style: AppTypography.bodySmall(color: textMuted)),
            ),
            data: (works) {
              if (works.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.palette_outlined,
                            size: 48, color: textMuted),
                        const SizedBox(height: 10),
                        Text('Este artista aún no tiene obras publicadas.',
                            style:
                                AppTypography.bodySmall(color: textMuted),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemCount: works.length,
                itemBuilder: (_, i) => _ArtworkCard(artwork: works[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppColors.bgCardDark : AppColors.bgCardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return GestureDetector(
      onTap: () => context.push('/artworks/${artwork.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              child: artwork.imagenes.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: artwork.imagenes.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        color: isDark
                            ? AppColors.bgSubtleDark
                            : AppColors.bgSubtleLight,
                      ),
                      errorWidget: (_, __, ___) => _ImagePlaceholder(
                          isDark: isDark),
                    )
                  : _ImagePlaceholder(isDark: isDark),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.titulo,
                    style: AppTypography.labelSemiBold(color: textPrimary)
                        .copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (artwork.precio != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '\$${artwork.precio!.toStringAsFixed(0)}',
                      style: AppTypography.caption(
                              color: AppColors.indigoClaro)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text('No disponible',
                        style: AppTypography.caption(color: textMuted)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
      child: const Center(
        child: Icon(Icons.image_outlined,
            color: AppColors.indigoClaro, size: 32),
      ),
    );
  }
}

// ─── Divisor entre secciones ──────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}
