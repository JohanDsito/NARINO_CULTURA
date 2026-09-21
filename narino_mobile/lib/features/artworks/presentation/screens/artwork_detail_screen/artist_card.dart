import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/artwork_model.dart';
import 'section_card.dart';

const _kSectionRadius = 16.0;

class ArtistCard extends StatelessWidget {
  const ArtistCard({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final avatarBg = isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    final avatarFg = isDark ? AppColors.tierraDark : AppColors.tierraProfunda;
    final linkColor = isDark ? AppColors.tierraDark : AppColors.tierraProfunda;

    return SectionCard(
      title: 'Artista',
      icon: Icons.person_outline,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_kSectionRadius - 4),
          onTap: () {
            if (artwork.artistaSlug.isNotEmpty) {
              context.push('/artistas/${artwork.artistaSlug}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: avatarBg,
                  backgroundImage: artwork.artistaFoto != null
                      ? NetworkImage(artwork.artistaFoto!)
                      : null,
                  child: artwork.artistaFoto == null
                      ? Text(
                          artwork.artistaNombre.isNotEmpty
                              ? artwork.artistaNombre[0].toUpperCase()
                              : '?',
                          style: AppTypography.displaySemiBold(color: avatarFg),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.artistaNombre,
                        style: AppTypography.labelSemiBold(color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ver perfil completo',
                        style: AppTypography.caption(color: linkColor),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
