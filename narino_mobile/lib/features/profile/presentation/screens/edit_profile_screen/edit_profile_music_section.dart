import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../musicians/domain/agrupaciones.dart';
import '../../../../musicians/domain/musician_model.dart';
import 'edit_profile_chip.dart';
import 'edit_profile_section.dart';

/// "Perfil musical": tipo de agrupación y géneros.
class EditProfileMusicSection extends StatelessWidget {
  const EditProfileMusicSection({
    super.key,
    required this.agrupacion,
    required this.generos,
    required this.todosGeneros,
    required this.cargando,
    required this.onAgrupacion,
    required this.onGenero,
    required this.onReintentar,
  });

  final String? agrupacion;

  /// IDs de los géneros elegidos.
  final Set<int> generos;
  final List<MusicGenreModel> todosGeneros;
  final bool cargando;
  final ValueChanged<String> onAgrupacion;

  /// Alterna un género (por ID).
  final ValueChanged<int> onGenero;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final etiqueta = AppTypography.labelSemiBold(color: nc.textSecondary);
    return EditProfileSection(
      titulo: 'Perfil musical',
      icon: Icons.music_note_rounded,
      accent: nc.musica,
      children: [
        Text('¿Cómo te presentas?', style: etiqueta),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in kAgrupaciones.entries)
              EditProfileChip(
                label: e.value,
                selected: agrupacion == e.key,
                accent: nc.musica,
                onTap: () => onAgrupacion(e.key),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Géneros', style: etiqueta),
        const SizedBox(height: 8),
        if (cargando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (todosGeneros.isEmpty)
          Row(
            children: [
              Expanded(
                child: Text('No pudimos cargar los géneros.',
                    style: AppTypography.bodySmall(color: nc.textMuted)),
              ),
              TextButton(
                  onPressed: onReintentar, child: const Text('Reintentar')),
            ],
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in todosGeneros)
                EditProfileChip(
                  label: g.name,
                  selected: generos.contains(g.id),
                  accent: nc.musica,
                  check: true,
                  onTap: () => onGenero(g.id),
                ),
            ],
          ),
      ],
    );
  }
}
