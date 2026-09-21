import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../musicians/presentation/screens/musicians_screen/musician_card.dart';
import '../../providers/music_discovery_provider.dart';

// ─── Results body ─────────────────────────────────────────────────────────────

class ResultsBody extends ConsumerWidget {
  const ResultsBody({
    super.key,
    required this.state,
    required this.textPrimary,
    required this.textMuted,
    required this.cs,
  });

  final MusicDiscoveryState state;
  final Color textPrimary;
  final Color textMuted;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.indigoClaro),
            SizedBox(height: 16),
            Text('Buscando artistas...'),
          ],
        ),
      );
    }

    if (state.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppColors.indigoClaro),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'Error al buscar',
                style: AppTypography.bodyMedium(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_outlined, size: 48, color: textMuted),
              const SizedBox(height: 12),
              Text(
                'No se encontraron músicos para\n"${state.lastQuery}"',
                style: AppTypography.bodyMedium(color: textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${state.results.length} músico${state.results.length == 1 ? '' : 's'} encontrado${state.results.length == 1 ? '' : 's'}',
            style: AppTypography.caption(color: textMuted),
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: state.results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) =>
                MusicianCard(musician: state.results[i]),
          ),
        ),
      ],
    );
  }
}
