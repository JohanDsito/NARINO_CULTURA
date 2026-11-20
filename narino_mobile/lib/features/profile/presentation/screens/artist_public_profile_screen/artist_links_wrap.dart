import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

/// Redes y sitio web del artista como pastillas que abren el navegador.
class ArtistLinksWrap extends StatelessWidget {
  const ArtistLinksWrap({super.key, required this.links});

  /// Pares red → URL, solo los que tienen valor.
  final List<MapEntry<String, String>> links;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in links)
          NcPressable(
            onTap: () => launchUrl(Uri.parse(e.value),
                mode: LaunchMode.externalApplication),
            semanticLabel: 'Abrir ${_nombre(e.key)}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: nc.azulA.tint,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: nc.azul.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icono(e.key), size: 16, color: nc.azul),
                  const SizedBox(width: 6),
                  Text(_nombre(e.key),
                      style: AppTypography.labelMedium(color: nc.azul)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static IconData _icono(String red) => switch (red) {
        'instagram' => Icons.camera_alt_outlined,
        'facebook' => Icons.facebook_rounded,
        'tiktok' => Icons.music_video_outlined,
        _ => Icons.language_rounded,
      };

  static String _nombre(String red) => switch (red) {
        'instagram' => 'Instagram',
        'facebook' => 'Facebook',
        'tiktok' => 'TikTok',
        'website' => 'Sitio web',
        _ => red,
      };
}
