import 'package:flutter/material.dart';

import '../../../../../shared/widgets/design/design.dart';

/// "¿Dónde se puede escuchar?": YouTube, Spotify y SoundCloud.
class ObraMusicalEnlacesSection extends StatelessWidget {
  const ObraMusicalEnlacesSection({
    super.key,
    required this.youtube,
    required this.spotify,
    required this.soundcloud,
  });

  final TextEditingController youtube;
  final TextEditingController spotify;
  final TextEditingController soundcloud;

  static String? _validarUrl(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    return Uri.tryParse(t)?.hasScheme == true
        ? null
        : 'Debe empezar por https://';
  }

  @override
  Widget build(BuildContext context) {
    return NcFormSection(
      title: '¿Dónde se puede escuchar?',
      hint: 'Agrega al menos un enlace para que el público pueda reproducirla.',
      children: [
        TextFormField(
          controller: youtube,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'YouTube',
            prefixIcon: Icon(Icons.smart_display_outlined),
          ),
          validator: _validarUrl,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: spotify,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Spotify',
            prefixIcon: Icon(Icons.graphic_eq_rounded),
          ),
          validator: _validarUrl,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: soundcloud,
          decoration: const InputDecoration(
            labelText: 'SoundCloud (enlace o código para insertar)',
            prefixIcon: Icon(Icons.cloud_outlined),
          ),
        ),
      ],
    );
  }
}
