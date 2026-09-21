import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../artworks/domain/artwork_model.dart';
import 'artwork_card.dart';

// ─── Obras del artista ────────────────────────────────────────────────────────

class ArtworksSection extends StatelessWidget {
  const ArtworksSection(
      {super.key, required this.slug, required this.worksAsync});

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
                itemBuilder: (_, i) => ArtworkCard(artwork: works[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}
