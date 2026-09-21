import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/events_state.dart';
import 'filter_chips.dart';

class FilterSection extends StatelessWidget {
  const FilterSection({
    super.key,
    required this.state,
    required this.artistController,
    required this.onArtistChanged,
  });

  final EventsState state;
  final TextEditingController artistController;
  final ValueChanged<String> onArtistChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    // Color de fondo del input coherente con el tema
    final fillColor = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;

    return Column(
      children: [
        const FilterChips(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: artistController,
            onChanged: onArtistChanged,
            style: AppTypography.bodySmall(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: 'Filtrar por artista...',
              hintStyle: AppTypography.bodySmall(color: textMuted),
              prefixIcon: Icon(Icons.person_search, size: 20, color: textMuted),
              filled: true,
              fillColor: fillColor,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
