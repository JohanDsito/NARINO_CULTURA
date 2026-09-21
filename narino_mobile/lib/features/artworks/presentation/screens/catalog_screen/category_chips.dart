import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/artwork_model.dart';
import '../../../domain/artwork_state.dart';
import '../../providers/artwork_provider.dart';

// ─── Chips de categoría ───────────────────────────────────────────────────────

class CategoryChips extends ConsumerWidget {
  const CategoryChips({
    super.key,
    required this.state,
    required this.onFilterTap,
  });

  final ArtworkState state;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    // ✅ FIX: selectedColor del chip resuelto desde el tema en lugar de color fijo
    final chipSelectedBg =
        isDark ? cs.primary.withValues(alpha: 0.18) : AppColors.tierraPalida;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_outlined,
                    size: 14,
                    color: state.hayFiltrosActivos ? cs.primary : textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.hayFiltrosActivos ? 'Filtros •' : 'Filtros',
                    style: AppTypography.caption(
                      color: state.hayFiltrosActivos ? cs.primary : textMuted,
                    ),
                  ),
                ],
              ),
              selected: state.hayFiltrosActivos,
              onSelected: (_) => onFilterTap(),
              backgroundColor: bgSubtle,
              selectedColor: chipSelectedBg,
              checkmarkColor: Colors.transparent,
              side: BorderSide(
                color: state.hayFiltrosActivos ? cs.primary : border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          ...kCategoriasNarino.take(8).map((cat) {
            final isSelected = state.categoriaFiltro == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  cat,
                  style: AppTypography.caption(
                    color: isSelected ? cs.primary : textMuted,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => ref
                    .read(artworkProvider.notifier)
                    .setCategoria(isSelected ? null : cat),
                backgroundColor: bgSubtle,
                selectedColor: chipSelectedBg,
                checkmarkColor: Colors.transparent,
                side: BorderSide(
                  color: isSelected ? cs.primary : border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
