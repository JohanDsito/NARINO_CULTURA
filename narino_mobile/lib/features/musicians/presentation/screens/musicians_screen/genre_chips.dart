import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/musician_model.dart';
import '../../providers/musician_provider.dart';

// ─── Genre chips ──────────────────────────────────────────────────────────────

class GenreChips extends ConsumerWidget {
  const GenreChips({super.key, required this.genres, required this.state});

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
