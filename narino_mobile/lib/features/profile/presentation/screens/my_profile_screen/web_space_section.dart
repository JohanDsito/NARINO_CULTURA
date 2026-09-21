import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'link_tile.dart';
import 'section_divider.dart';
import 'section_label.dart';

// ─── Mi espacio web ───────────────────────────────────────────────────────────

class WebSpaceSection extends StatelessWidget {
  const WebSpaceSection({super.key, required this.links});

  final Map<String, String> links;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = isDark ? AppColors.bgCardDark : AppColors.bgCardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final entries = links.entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(label: 'Mi espacio web'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            children: entries
                .expand<Widget>((e) => [
                      LinkTile(platform: e.key, url: e.value),
                      const SectionDivider(),
                    ])
                .toList()
              ..removeLast(),
          ),
        ),
      ],
    );
  }
}
