import 'package:flutter/material.dart';

import 'edit_profile_section.dart';
import 'enlaces.dart';

/// "Tus redes": un campo por red, acepta enlace o `@usuario`.
class EditProfileLinksSection extends StatelessWidget {
  const EditProfileLinksSection({super.key, required this.links});

  /// Red (`website`, `instagram`, `facebook`, `tiktok`) → su campo.
  final Map<String, TextEditingController> links;

  @override
  Widget build(BuildContext context) {
    final redes = links.keys.toList();
    return EditProfileSection(
      titulo: 'Tus redes',
      subtitulo: 'Pega el enlace o escribe tu @usuario.',
      children: [
        for (final red in redes) ...[
          TextFormField(
            controller: links[red],
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: _nombre(red),
              hintText: _ejemplo(red),
              prefixIcon: Icon(_icono(red)),
            ),
            validator: (v) => enlaceValido(normalizarEnlace(red, v ?? ''))
                ? null
                : 'Revisa el enlace',
          ),
          if (red != redes.last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  static String _nombre(String red) => switch (red) {
        'website' => 'Sitio web',
        'instagram' => 'Instagram',
        'facebook' => 'Facebook',
        _ => 'TikTok',
      };

  static String _ejemplo(String red) => switch (red) {
        'website' => 'tusitio.com',
        'facebook' => 'facebook.com/tu.pagina',
        _ => '@tuusuario',
      };

  static IconData _icono(String red) => switch (red) {
        'website' => Icons.language_rounded,
        'instagram' => Icons.camera_alt_outlined,
        'facebook' => Icons.facebook_rounded,
        _ => Icons.music_video_outlined,
      };
}
