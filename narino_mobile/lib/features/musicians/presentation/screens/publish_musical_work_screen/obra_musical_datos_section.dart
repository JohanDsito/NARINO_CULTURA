import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import 'duracion.dart';

/// Tipos del backend (`MusicalWork.WorkType`): etiqueta e ícono.
const kTiposObraMusical = <String, (String, IconData)>{
  'VIDEO': ('Video musical', Icons.smart_display_outlined),
  'LIVE': ('En vivo', Icons.mic_external_on_outlined),
  'STUDIO': ('Estudio', Icons.album_outlined),
  'COVER': ('Cover', Icons.repeat_rounded),
  'PODCAST': ('Podcast', Icons.podcasts_rounded),
};

/// "¿Qué vas a compartir?": tipo, título, descripción, lanzamiento y duración.
class ObraMusicalDatosSection extends StatelessWidget {
  const ObraMusicalDatosSection({
    super.key,
    required this.tipo,
    required this.onTipo,
    required this.titulo,
    required this.descripcion,
    required this.lanzamiento,
    required this.onElegirFecha,
    required this.duracion,
  });

  final String? tipo;
  final ValueChanged<String> onTipo;
  final TextEditingController titulo;
  final TextEditingController descripcion;
  final DateTime? lanzamiento;
  final VoidCallback onElegirFecha;
  final TextEditingController duracion;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final f = lanzamiento;
    return NcFormSection(
      title: '¿Qué vas a compartir?',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in kTiposObraMusical.entries)
              ChoiceChip(
                avatar: Icon(e.value.$2,
                    size: 16,
                    color: tipo == e.key ? nc.musica.onFill : nc.musica.ink),
                label: Text(e.value.$1),
                selected: tipo == e.key,
                showCheckmark: false,
                onSelected: (_) => onTipo(e.key),
                selectedColor: nc.musica.fill,
                side: BorderSide(
                    color: tipo == e.key ? nc.musica.fill : nc.border),
                labelStyle: AppTypography.labelMedium(
                  color: tipo == e.key ? nc.musica.onFill : nc.textPrimary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
          ],
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: titulo,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Título'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Ponle un título' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: descripcion,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Descripción (opcional)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onElegirFecha,
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(f == null
                    ? 'Lanzamiento'
                    : '${f.day}/${f.month}/${f.year}'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: duracion,
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'))
                ],
                decoration: const InputDecoration(
                  labelText: 'Duración',
                  hintText: '3:45',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty || segundosDeDuracion(v!) != null
                        ? null
                        : 'Usa min:seg',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
