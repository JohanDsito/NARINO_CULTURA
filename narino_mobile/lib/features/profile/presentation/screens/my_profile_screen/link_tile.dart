import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class LinkTile extends StatelessWidget {
  const LinkTile({super.key, required this.platform, required this.url});

  final String platform;
  final String url;

  static const _platforms = <String, (IconData, String, Color)>{
    'instagram': (Icons.camera_alt_outlined, 'Instagram', Color(0xFFE1306C)),
    'facebook': (Icons.facebook_outlined, 'Facebook', Color(0xFF1877F2)),
    'tiktok': (Icons.music_note_outlined, 'TikTok', Color(0xFF69C9D0)),
    'website': (Icons.language_outlined, 'Sitio web', AppColors.indigoClaro),
  };

  (IconData, String, Color) get _info =>
      _platforms[platform.toLowerCase()] ??
      (Icons.link_outlined, platform, AppColors.indigoClaro);

  String get _displayUrl {
    var u = url;
    if (u.startsWith('https://')) u = u.substring(8);
    if (u.startsWith('http://')) u = u.substring(7);
    if (u.startsWith('www.')) u = u.substring(4);
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u.length > 36 ? '${u.substring(0, 33)}…' : u;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final (icon, name, color) = _info;

    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTypography.labelSemiBold(color: textPrimary)),
                  Text(_displayUrl,
                      style: AppTypography.caption(color: textMuted)),
                ],
              ),
            ),
            Icon(Icons.open_in_new_outlined, size: 16, color: textMuted),
          ],
        ),
      ),
    );
  }
}
