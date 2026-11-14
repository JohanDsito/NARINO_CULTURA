import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../musicians/domain/agrupaciones.dart';
import '../../../../musicians/domain/musician_model.dart';

/// Campos del paso 2 (perfil musical): nombre, formato y géneros.
class MusicianStepForm extends StatelessWidget {
  const MusicianStepForm({
    super.key,
    required this.nombre,
    required this.nombreError,
    required this.onNombreChanged,
    required this.agrupacion,
    required this.onAgrupacion,
    required this.generos,
    required this.seleccionados,
    required this.cargandoGeneros,
    required this.onGenero,
    required this.enabled,
  });

  final TextEditingController nombre;
  final bool nombreError;
  final VoidCallback onNombreChanged;
  final String? agrupacion;

  /// `null` deselecciona.
  final ValueChanged<String?> onAgrupacion;
  final List<MusicGenreModel> generos;
  final Set<int> seleccionados;
  final bool cargandoGeneros;
  final ValueChanged<int> onGenero;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final musica = nc.tomateA;

    Widget label(String text, {String? hint}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: AppTypography.labelSemiBold(color: nc.textPrimary)
                    .copyWith(fontSize: 14)),
            if (hint != null) ...[
              const SizedBox(height: 2),
              Text(hint,
                  style: AppTypography.bodySmall(color: nc.textSecondary)),
            ],
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label('Nombre artístico'),
        const SizedBox(height: 10),
        TextFormField(
          controller: nombre,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => onNombreChanged(),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.mic_none_rounded),
            hintText: 'Nombre con el que te conocen',
            errorText: nombreError ? 'Escribe tu nombre artístico' : null,
          ),
        ),
        const SizedBox(height: 22),
        label('Formato'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in kAgrupaciones.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: agrupacion == e.key,
                showCheckmark: false,
                onSelected:
                    enabled ? (v) => onAgrupacion(v ? e.key : null) : null,
                selectedColor: musica.fill,
                labelStyle: AppTypography.labelMedium(
                  color: agrupacion == e.key ? musica.onFill : nc.textPrimary,
                ).copyWith(fontWeight: FontWeight.w600),
                side: BorderSide(
                  color: agrupacion == e.key ? musica.fill : nc.border,
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        label('Géneros musicales',
            hint: 'Elige todos los que definen tu música.'),
        const SizedBox(height: 10),
        if (cargandoGeneros)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (generos.isEmpty)
          NcBanner(
            accent: nc.oroA,
            message: 'No pudimos cargar los géneros. Puedes agregarlos '
                'luego desde tu perfil.',
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in generos)
                FilterChip(
                  label: Text(g.name),
                  selected: seleccionados.contains(g.id),
                  onSelected: enabled ? (_) => onGenero(g.id) : null,
                  selectedColor: nc.azulA.tint,
                  checkmarkColor: nc.azul,
                  side: BorderSide(
                    color: seleccionados.contains(g.id) ? nc.azul : nc.border,
                  ),
                  labelStyle: AppTypography.labelMedium(
                    color:
                        seleccionados.contains(g.id) ? nc.azul : nc.textPrimary,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
