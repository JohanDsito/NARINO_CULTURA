import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/nc_theme.dart';
import 'profile_option_group.dart';
import 'profile_option_tile.dart';
import 'profile_section_title.dart';

/// "Mi espacio web": redes y sitio del perfil, abren en el navegador.
class ProfileWebLinksSection extends StatelessWidget {
  const ProfileWebLinksSection({super.key, required this.links});

  /// Pares red → URL, solo los que tienen valor.
  final List<MapEntry<String, String>> links;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle('Mi espacio web'),
        ProfileOptionGroup(children: [
          for (final e in links)
            ProfileOptionTile(
              icon: _icono(e.key),
              accent: nc.azulA,
              title: _nombre(e.key),
              subtitle: e.value.replaceFirst(RegExp(r'^https?://'), ''),
              trailingIcon: Icons.open_in_new_rounded,
              onTap: () => launchUrl(Uri.parse(e.value),
                  mode: LaunchMode.externalApplication),
            ),
        ]),
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
