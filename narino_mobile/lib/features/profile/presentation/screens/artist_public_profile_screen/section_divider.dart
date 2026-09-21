import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

// ─── Divisor entre secciones ──────────────────────────────────────────────────

class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}
