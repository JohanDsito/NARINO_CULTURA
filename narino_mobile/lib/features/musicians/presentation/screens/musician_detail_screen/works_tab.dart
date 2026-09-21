import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../providers/musician_provider.dart';
import 'work_card.dart';

class WorksTab extends ConsumerWidget {
  const WorksTab({super.key, required this.slug});

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
          itemBuilder: (_, i) => WorkCard(work: works[i], isDark: isDark),
        );
      },
    );
  }
}
