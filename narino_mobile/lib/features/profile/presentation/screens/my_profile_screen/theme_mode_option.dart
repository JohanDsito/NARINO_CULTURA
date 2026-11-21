import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/providers/theme_provider.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

/// Selector de tema: Sistema / Claro / Oscuro.
class ThemeModeOption extends ConsumerWidget {
  const ThemeModeOption({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final mode = ref.watch(themeModeProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: nc.magentaA.tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Icon(Icons.contrast_rounded, size: 20, color: nc.magentaA.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Apariencia',
                style: AppTypography.labelSemiBold(color: nc.textPrimary)
                    .copyWith(fontSize: 15)),
          ),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              selectedBackgroundColor: nc.azul,
              selectedForegroundColor: nc.onAzul,
              side: BorderSide(color: nc.border),
            ),
            segments: const [
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.phone_android_rounded, size: 18),
                  tooltip: 'Como el sistema'),
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined, size: 18),
                  tooltip: 'Claro'),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined, size: 18),
                  tooltip: 'Oscuro'),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).setMode(s.first),
          ),
        ],
      ),
    );
  }
}
