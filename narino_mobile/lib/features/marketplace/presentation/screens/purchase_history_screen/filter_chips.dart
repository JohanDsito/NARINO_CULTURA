import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../purchase_history_screen.dart' show kFiltros, labelFiltro;

// ─── Filtros ──────────────────────────────────────────────────────────────────

class FilterChips extends StatelessWidget {
  const FilterChips({super.key, required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final selectedBg =
        isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: kFiltros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = kFiltros[i];
          final isSelected = selected == f;
          return FilterChip(
            label: Text(
              labelFiltro(f),
              style: AppTypography.caption(
                color: isSelected ? cs.primary : textMuted,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelect(f),
            backgroundColor: bgSubtle,
            selectedColor: selectedBg,
            checkmarkColor: Colors.transparent,
            side: BorderSide(
              color: isSelected ? cs.primary : border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99),
            ),
          );
        },
      ),
    );
  }
}
