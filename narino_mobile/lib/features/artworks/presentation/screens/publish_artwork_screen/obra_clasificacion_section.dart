import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/artwork_model.dart';

/// "Categoría": categoría (obligatoria), técnica y dimensiones.
class ObraClasificacionSection extends StatelessWidget {
  const ObraClasificacionSection({
    super.key,
    required this.categorias,
    required this.categoriaId,
    required this.tecnica,
    required this.dimensiones,
    required this.editable,
    required this.mostrarError,
    required this.onCategoria,
    required this.onTecnica,
  });

  final List<CategoryModel> categorias;
  final int? categoriaId;
  final String? tecnica;
  final TextEditingController dimensiones;
  final bool editable;

  /// Marca la categoría en rojo si se intentó publicar sin elegirla.
  final bool mostrarError;
  final ValueChanged<int> onCategoria;
  final ValueChanged<String?> onTecnica;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final falta = mostrarError && categoriaId == null;
    return NcFormSection(
      title: 'Categoría',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (categorias.isEmpty)
              Text('Cargando categorías…',
                  style: AppTypography.bodySmall(color: nc.textSecondary)),
            for (final c in categorias)
              ChoiceChip(
                label: Text(c.displayName),
                selected: categoriaId == c.id,
                showCheckmark: false,
                onSelected: editable ? (_) => onCategoria(c.id) : null,
                selectedColor: nc.catalogo.fill,
                side: BorderSide(
                  color: categoriaId == c.id
                      ? nc.catalogo.fill
                      : (falta ? nc.tomateA.fill : nc.border),
                ),
                labelStyle: AppTypography.labelMedium(
                  color:
                      categoriaId == c.id ? nc.catalogo.onFill : nc.textPrimary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
          ],
        ),
        if (falta) ...[
          const SizedBox(height: 8),
          Text('Elige una categoría',
              style: AppTypography.bodySmall(color: nc.tomateA.ink)),
        ],
        const SizedBox(height: 20),
        DropdownButtonFormField<String?>(
          initialValue: tecnica,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Técnica (opcional)',
            prefixIcon: Icon(Icons.brush_outlined),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Sin especificar')),
            // Conserva una técnica guardada que no esté en la lista.
            for (final t in {...kTecnicasNarino, if (tecnica != null) tecnica!})
              DropdownMenuItem(value: t, child: Text(t)),
          ],
          onChanged: editable ? onTecnica : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: dimensiones,
          enabled: editable,
          decoration: const InputDecoration(
            labelText: 'Dimensiones (opcional)',
            hintText: 'Ej.: 50 × 70 cm',
            prefixIcon: Icon(Icons.straighten_rounded),
          ),
        ),
      ],
    );
  }
}
