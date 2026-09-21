import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'section_divider.dart';

// ─── Contenedor de sección con borde ─────────────────────────────────────────

class MenuSection extends StatelessWidget {
  const MenuSection({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppColors.bgCardDark : AppColors.bgCardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: children
            .expand((child) => [child, const SectionDivider()])
            .toList()
          ..removeLast(),
      ),
    );
  }
}
