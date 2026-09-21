import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/theme_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Toggle de tema ───────────────────────────────────────────────────────────

class ThemeToggleTile extends ConsumerWidget {
  const ThemeToggleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final iconBg = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final currentMode = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              currentMode == ThemeMode.dark
                  ? Icons.dark_mode_outlined
                  : currentMode == ThemeMode.light
                      ? Icons.light_mode_outlined
                      : Icons.settings_suggest_outlined,
              color: cs.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apariencia',
                  style: AppTypography.labelSemiBold(color: textPrimary),
                ),
                Text(
                  'Tema de la aplicación',
                  style: AppTypography.caption(color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<ThemeMode>(
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              textStyle: AppTypography.caption(color: textPrimary)
                  .copyWith(fontSize: 10),
              selectedBackgroundColor: cs.primary,
              selectedForegroundColor: cs.onPrimary,
              foregroundColor: textMuted,
            ),
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.settings_suggest_outlined, size: 15),
                label: Text('Auto'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined, size: 15),
                label: Text('Claro'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined, size: 15),
                label: Text('Oscuro'),
              ),
            ],
            selected: {currentMode},
            onSelectionChanged: (selection) =>
                ref.read(themeModeProvider.notifier).setMode(selection.first),
          ),
        ],
      ),
    );
  }
}
