import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/profile_provider.dart';

class FollowingScreen extends ConsumerWidget {
  const FollowingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(followingProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Artistas que sigo',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro)
              .copyWith(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.oroClaro),
          onPressed: () => context.pop(),
        ),
      ),
      body: followingAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (artists) => artists.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: textMuted,
                      size: 72,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No sigues a ningún artista',
                      style: AppTypography.displaySemiBold(
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Explora el catálogo y sigue a los artistas que te gusten',
                      style: AppTypography.bodySmall(
                        color: textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: artists.length,
                itemBuilder: (_, i) {
                  final artist = artists[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: border),
                    ),
                    tileColor: bgCard,
                    leading: CircleAvatar(
                      backgroundColor: isDark
                          ? AppColors.bgSubtleDark
                          : AppColors.tierraPalida,
                      backgroundImage: artist.fotoUrl != null
                          ? NetworkImage(artist.fotoUrl!)
                          : null,
                      child: artist.fotoUrl == null
                          ? Text(
                              artist.nombreArtistico[0].toUpperCase(),
                              style: AppTypography.labelSemiBold(
                                color: cs.primary,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      artist.nombreArtistico,
                      style: AppTypography.labelSemiBold(
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      artist.disciplina,
                      style: AppTypography.caption(
                        color: textMuted,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: textMuted),
                    onTap: () => context.push('/artistas/${artist.id}'),
                  );
                },
              ),
      ),
    );
  }
}
