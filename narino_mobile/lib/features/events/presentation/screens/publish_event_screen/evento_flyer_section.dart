import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

/// "Flyer (opcional)": enlace a una imagen y su vista previa.
class EventoFlyerSection extends StatelessWidget {
  const EventoFlyerSection({super.key, required this.flyer});

  final TextEditingController flyer;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final url = flyer.text.trim();
    final valido = Uri.tryParse(url)?.hasScheme == true;
    return NcFormSection(
      title: 'Flyer (opcional)',
      hint: 'Pega el enlace de una imagen ya publicada (el backend aún no '
          'permite subir archivos).',
      children: [
        TextFormField(
          controller: flyer,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Enlace de la imagen',
            hintText: 'https://…',
            prefixIcon: Icon(Icons.link_rounded),
          ),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return null;
            return Uri.tryParse(t)?.hasScheme == true
                ? null
                : 'Debe empezar por https://';
          },
        ),
        if (valido) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Center(
                  child: Text('No se pudo cargar la imagen',
                      style: AppTypography.bodySmall(color: nc.tomateA.ink)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
