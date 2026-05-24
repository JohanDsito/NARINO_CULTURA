import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/musician_model.dart';
import '../providers/musician_provider.dart';

class MusicianDetailScreen extends ConsumerStatefulWidget {
  const MusicianDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<MusicianDetailScreen> createState() =>
      _MusicianDetailScreenState();
}

class _MusicianDetailScreenState
    extends ConsumerState<MusicianDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicianAsync = ref.watch(musicianDetailProvider(widget.slug));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: musicianAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.indigoClaro),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_off_outlined,
                  size: 48, color: AppColors.indigoClaro),
              const SizedBox(height: 12),
              Text(e.toString(),
                  style: AppTypography.bodyMedium(color: AppColors.error),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(musicianDetailProvider(widget.slug)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigoClaro,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (musician) => NestedScrollView(
          headerSliverBuilder: (context, _) => [
            _MusicianSliverAppBar(musician: musician, isDark: isDark),
          ],
          body: Column(
            children: [
              TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.indigoClaro,
                unselectedLabelColor: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
                indicatorColor: AppColors.indigoClaro,
                tabs: const [
                  Tab(text: 'Obras'),
                  Tab(text: 'Reseñas'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _WorksTab(slug: widget.slug),
                    _ReviewsTab(slug: widget.slug),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sliver AppBar ────────────────────────────────────────────────────────────

class _MusicianSliverAppBar extends ConsumerWidget {
  const _MusicianSliverAppBar({
    required this.musician,
    required this.isDark,
  });

  final MusicianModel musician;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.obsidiana,
      foregroundColor: AppColors.oroClaro,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            musician.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: musician.coverUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.indigoNoche,
                    ),
                  )
                : Container(color: AppColors.indigoNoche),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: musician.photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: musician.photoUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _SmallPlaceholder(),
                          )
                        : _SmallPlaceholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                musician.name,
                                style: AppTypography.displaySemiBold(
                                    color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (musician.isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.verified,
                                    size: 16,
                                    color: AppColors.indigoClaro),
                              ),
                          ],
                        ),
                        if (musician.city != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 2),
                              Text(musician.city!,
                                  style: AppTypography.caption(
                                      color: Colors.white70)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  _FollowDetailButton(musician: musician),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: _ProfileStats(
          musician: musician,
          textPrimary: textPrimary,
          textMuted: textMuted,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _SmallPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.indigoNoche,
      child: const Icon(Icons.music_note_outlined,
          color: AppColors.indigoClaro, size: 28),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({
    required this.musician,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
  });

  final MusicianModel musician;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgCard = theme.cardTheme.color ?? theme.colorScheme.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      color: bgCard,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (musician.bio != null && musician.bio!.isNotEmpty) ...[
            Text(
              musician.bio!,
              style: AppTypography.bodySmall(color: textMuted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
          ],
          if (musician.genres.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: musician.genres.map((g) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        AppColors.indigoClaro.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: AppColors.indigoClaro
                            .withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    g,
                    style: AppTypography.caption(
                        color: AppColors.indigoClaro),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              _Stat(
                icon: Icons.people_outline,
                value: '${musician.followersCount}',
                label: 'Seguidores',
                color: textMuted,
              ),
              const SizedBox(width: 24),
              _Stat(
                icon: Icons.star_outline,
                value: musician.averageRating.toStringAsFixed(1),
                label: 'Calificación',
                color: textMuted,
              ),
              const SizedBox(width: 24),
              _Stat(
                icon: Icons.rate_review_outlined,
                value: '${musician.reviewsCount}',
                label: 'Reseñas',
                color: textMuted,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: border, height: 1),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppTypography.labelSemiBold(color: color)),
            Text(label, style: AppTypography.caption(color: color)),
          ],
        ),
      ],
    );
  }
}

class _FollowDetailButton extends ConsumerWidget {
  const _FollowDetailButton({required this.musician});

  final MusicianModel musician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = musician.isFollowing;

    return GestureDetector(
      onTap: () async {
        await ref
            .read(musicianRepositoryProvider)
            .toggleFollow(musician.slug);
        ref.invalidate(musicianDetailProvider(musician.slug));
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isFollowing
              ? Colors.white.withValues(alpha: 0.15)
              : AppColors.indigoClaro,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isFollowing
                ? Colors.white.withValues(alpha: 0.5)
                : AppColors.indigoClaro,
          ),
        ),
        child: Text(
          isFollowing ? 'Siguiendo' : 'Seguir',
          style: AppTypography.caption(color: Colors.white),
        ),
      ),
    );
  }
}

// ─── Works tab ────────────────────────────────────────────────────────────────

class _WorksTab extends ConsumerWidget {
  const _WorksTab({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worksAsync = ref.watch(musicianWorksProvider(slug));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return worksAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.indigoClaro),
      ),
      error: (e, _) => Center(
        child: Text(e.toString(),
            style: AppTypography.bodyMedium(color: AppColors.error)),
      ),
      data: (works) {
        if (works.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.library_music_outlined,
                    size: 48, color: textMuted),
                const SizedBox(height: 12),
                Text('Sin obras publicadas',
                    style: AppTypography.bodyMedium(color: textMuted)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: works.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _WorkCard(work: works[i], isDark: isDark),
        );
      },
    );
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({required this.work, required this.isDark});

  final MusicalWorkModel work;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgCard = theme.cardTheme.color ?? theme.colorScheme.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: work.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: work.coverUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _WorkPlaceholder(isDark: isDark),
                  )
                : _WorkPlaceholder(isDark: isDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(work.title,
                    style: AppTypography.labelSemiBold(color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (work.genre != null)
                  Text(work.genre!,
                      style: AppTypography.caption(color: AppColors.indigoClaro),
                      maxLines: 1),
                if (work.year != null)
                  Text('${work.year}',
                      style: AppTypography.caption(color: textMuted)),
              ],
            ),
          ),
          if (work.audioUrl != null)
            const Icon(Icons.play_circle_outline,
                color: AppColors.indigoClaro, size: 28),
        ],
      ),
    );
  }
}

class _WorkPlaceholder extends StatelessWidget {
  const _WorkPlaceholder({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      color: isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
      child: const Icon(Icons.music_note_outlined,
          color: AppColors.indigoClaro, size: 22),
    );
  }
}

// ─── Reviews tab ──────────────────────────────────────────────────────────────

class _ReviewsTab extends ConsumerWidget {
  const _ReviewsTab({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(musicianReviewsProvider(slug));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return reviewsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.indigoClaro),
      ),
      error: (e, _) => Center(
        child: Text(e.toString(),
            style: AppTypography.bodyMedium(color: AppColors.error)),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 48, color: textMuted),
                const SizedBox(height: 12),
                Text('Aún no hay reseñas',
                    style: AppTypography.bodyMedium(color: textMuted)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) =>
              _ReviewCard(review: reviews[i], isDark: isDark),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.isDark});

  final MusicianReviewModel review;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgCard = theme.cardTheme.color ?? theme.colorScheme.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.indigoClaro.withValues(alpha: 0.2),
                backgroundImage: review.reviewerAvatar != null
                    ? CachedNetworkImageProvider(review.reviewerAvatar!)
                    : null,
                child: review.reviewerAvatar == null
                    ? Text(
                        review.reviewerName.isNotEmpty
                            ? review.reviewerName[0].toUpperCase()
                            : '?',
                        style: AppTypography.labelSemiBold(
                            color: AppColors.indigoClaro),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName,
                        style:
                            AppTypography.labelSemiBold(color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating
                              ? Icons.star
                              : Icons.star_outline,
                          size: 13,
                          color: i < review.rating
                              ? AppColors.oroAndino
                              : textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: AppTypography.caption(color: textMuted),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!,
                style: AppTypography.bodySmall(color: textMuted)),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  return '${dt.day}/${dt.month}/${dt.year}';
}
