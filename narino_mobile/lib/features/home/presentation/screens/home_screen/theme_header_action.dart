import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/theme_provider.dart';
import '../../../../../shared/widgets/design/design.dart';

class ThemeHeaderAction extends ConsumerWidget {
  const ThemeHeaderAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return NcIconButton(
      icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(brightness),
    );
  }
}
