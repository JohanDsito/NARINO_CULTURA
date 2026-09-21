import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Biografía ────────────────────────────────────────────────────────────────

class BioSection extends StatelessWidget {
  const BioSection({super.key, required this.bio});

  final String bio;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Text(
        bio,
        style: AppTypography.quoteItalic(color: textSecondary)
            .copyWith(fontSize: 14, height: 1.55),
      ),
    );
  }
}
