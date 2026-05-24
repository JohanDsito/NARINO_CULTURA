import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/musician_model.dart';
import '../providers/musician_provider.dart';

class MusiciansScreen extends ConsumerStatefulWidget {
  const MusiciansScreen({super.key});

  @override
  ConsumerState<MusiciansScreen> createState() => _MusiciansScreenState();
}

class _MusiciansScreenState extends ConsumerState<MusiciansScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicianListProvider);
    final genresAsync = ref.watch(musicGenresProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Músicos',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note_outlined, color: AppColors.oroClaro),
            tooltip: 'Descubrimiento musical',
            onPressed: () => context.push('/music-discovery'),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchCtrl,
            isDark: isDark,
            onChanged: (v) =>
                ref.read(musicianListProvider.notifier).setSearch(v),
            onClear: () {
              setState(_searchCtrl.clear);
              ref.read(musicianListProvider.notifier).setSearch('');
            },
          ),
          genresAsync.when(
            data: (genres) => _GenreChips(genres: genres, state: state),
            loading: () => const SizedBox(height: 40),
            error: (_, __) => const SizedBox(height: 40),
          ),
          Expanded(
            child: RefreshIndicator(
              color: cs.primary,
              onRefresh: () async =>
                  ref.read(musicianListProvider.notifier).load(),
              child: _MusicianBody(state: state),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isDark,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final fillColor =
        isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        style: AppTypography.bodyMedium(color: textPrimary),
        decoration: InputDecoration(
          hintText: 'Buscar músicos por nombre o ciudad...',
          hintStyle: AppTypography.bodyMedium(color: textMuted),
          filled: true,
          fillColor: fillColor,
          prefixIcon: Icon(Icons.search_outlined, color: textMuted),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: textMuted),
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Genre chips ──────────────────────────────────────────────────────────────

class _GenreChips extends ConsumerWidget {
  const _GenreChips({required this.genres, required this.state});

  final List<MusicGenreModel> genres;
  final MusicianListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final chipSelectedBg =
        isDark ? cs.primary.withValues(alpha: 0.18) : AppColors.indigoClaro.withValues(alpha: 0.12);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: genres.map((g) {
          final isSelected = state.genreFilter == g.slug;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                g.name,
                style: AppTypography.caption(
                  color: isSelected ? AppColors.indigoClaro : textMuted,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => ref
                  .read(musicianListProvider.notifier)
                  .setGenre(isSelected ? null : g.slug),
              backgroundColor: bgSubtle,
              selectedColor: chipSelectedBg,
              checkmarkColor: Colors.transparent,
              side: BorderSide(
                color: isSelected ? AppColors.indigoClaro : border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _MusicianBody extends ConsumerWidget {
  const _MusicianBody({required this.state});

  final MusicianListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 140),
          Center(
            child: CircularProgressIndicator(
              color: AppColors.indigoClaro,
              strokeWidth: 2,
            ),
          ),
        ],
      );
    }

    if (state.hasError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.cloud_off_outlined,
                    size: 48,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight),
                const SizedBox(height: 12),
                Text(
                  state.errorMessage ?? 'Error al cargar músicos',
                  style: AppTypography.bodyMedium(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(musicianListProvider.notifier).load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigoClaro,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state.musicians.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textMuted =
          isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 70),
          Center(
            child: Column(
              children: [
                Icon(Icons.music_off_outlined, size: 56, color: textMuted),
                const SizedBox(height: 14),
                Text(
                  'No se encontraron músicos',
                  style: AppTypography.bodyMedium(color: textMuted),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      itemCount: state.musicians.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => MusicianCard(musician: state.musicians[i]),
    );
  }
}

// ─── MusicianCard (shared widget) ────────────────────────────────────────────

class MusicianCard extends ConsumerWidget {
  const MusicianCard({super.key, required this.musician});

  final MusicianModel musician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return GestureDetector(
      onTap: () => context.push('/musicians/${musician.slug}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: musician.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: musician.photoUrl!,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _AvatarPlaceholder(
                        isDark: isDark,
                      ),
                    )
                  : _AvatarPlaceholder(isDark: isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          musician.name,
                          style: AppTypography.labelSemiBold(color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (musician.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            size: 14,
                            color: AppColors.indigoClaro,
                          ),
                        ),
                    ],
                  ),
                  if (musician.city != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: textMuted),
                        const SizedBox(width: 2),
                        Text(
                          musician.city!,
                          style: AppTypography.caption(color: textMuted),
                        ),
                      ],
                    ),
                  ],
                  if (musician.genres.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: musician.genres.take(3).map((g) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.indigoClaro.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            g,
                            style: AppTypography.caption(
                                color: AppColors.indigoClaro),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 13, color: textMuted),
                      const SizedBox(width: 3),
                      Text(
                        '${musician.followersCount}',
                        style: AppTypography.caption(color: textMuted),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.star_outline, size: 13, color: textMuted),
                      const SizedBox(width: 3),
                      Text(
                        musician.averageRating.toStringAsFixed(1),
                        style: AppTypography.caption(color: textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _FollowButton(musician: musician),
          ],
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      color: isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
      child: const Icon(
        Icons.music_note_outlined,
        color: AppColors.indigoClaro,
        size: 28,
      ),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.musician});

  final MusicianModel musician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = musician.isFollowing;

    return GestureDetector(
      onTap: () =>
          ref.read(musicianListProvider.notifier).toggleFollow(musician.slug),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing
              ? AppColors.indigoClaro.withValues(alpha: 0.12)
              : AppColors.indigoClaro,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.indigoClaro),
        ),
        child: Text(
          isFollowing ? 'Siguiendo' : 'Seguir',
          style: AppTypography.caption(
            color:
                isFollowing ? AppColors.indigoClaro : Colors.white,
          ),
        ),
      ),
    );
  }
}
