import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/profile_model.dart';
import 'stat_item.dart';

// ─── Estadísticas + botón Seguir ─────────────────────────────────────────────

class StatsRow extends StatelessWidget {
  const StatsRow({
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
          StatItem(
              value: '${profile.seguidores}',
              label: 'Seguidores',
              textPrimary: textPrimary,
              textMuted: textMuted),
          const SizedBox(width: 4),
          Container(width: 1, height: 28, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(width: 16),
          StatItem(
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
