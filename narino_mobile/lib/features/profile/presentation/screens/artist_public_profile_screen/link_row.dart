import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class LinkRow extends StatelessWidget {
  const LinkRow({
    super.key,
    required this.platform,
    required this.url,
    required this.textPrimary,
    required this.textMuted,
    required this.platforms,
  });

  final String platform;
  final String url;
  final Color textPrimary;
  final Color textMuted;
  final Map<String, (IconData, String, Color)> platforms;

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
    final (icon, name, color) = platforms[platform.toLowerCase()] ??
        (Icons.link_outlined, platform, AppColors.indigoClaro);

    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          AppTypography.labelSemiBold(color: textPrimary)),
                  Text(_displayUrl,
                      style: AppTypography.caption(color: textMuted)),
                ],
              ),
            ),
            Icon(Icons.open_in_new_outlined, size: 15, color: textMuted),
          ],
        ),
      ),
    );
  }
}
