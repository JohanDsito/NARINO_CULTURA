import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../providers/musician_provider.dart';
import 'musician_card.dart';

// ─── Body ─────────────────────────────────────────────────────────────────────

class MusicianBody extends ConsumerWidget {
  const MusicianBody({super.key, required this.state});

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
