import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'link_row.dart';

// ─── Links ────────────────────────────────────────────────────────────────────

class LinksSection extends StatelessWidget {
  const LinksSection({super.key, required this.links});

  final List<MapEntry<String, String>> links;

  static const _platforms = <String, (IconData, String, Color)>{
    'instagram': (Icons.camera_alt_outlined, 'Instagram', Color(0xFFE1306C)),
    'facebook': (Icons.facebook_outlined, 'Facebook', Color(0xFF1877F2)),
    'tiktok': (Icons.music_note_outlined, 'TikTok', Color(0xFF69C9D0)),
    'website': (Icons.language_outlined, 'Sitio web', AppColors.indigoClaro),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final bgCard = isDark ? AppColors.bgCardDark : AppColors.bgCardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Redes y enlaces',
              style: AppTypography.labelSemiBold(color: textPrimary)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Column(
              children: links
                  .expand<Widget>((e) => [
                        LinkRow(
                            platform: e.key,
                            url: e.value,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            platforms: _platforms),
                        Divider(height: 1, indent: 56, color: border),
                      ])
                  .toList()
                ..removeLast(),
            ),
          ),
        ],
      ),
    );
  }
}
