import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import 'orden_formato.dart';

/// Fila de chips para filtrar por estado.
class EstadoFiltroChips extends StatelessWidget {
  const EstadoFiltroChips({
    super.key,
    required this.opciones,
    required this.selected,
    required this.onSelect,
  });

  /// (valor, etiqueta)
  final List<(String, String)> opciones;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: opciones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (valor, label) = opciones[i];
          final sel = valor == selected;
          final accent =
              valor == 'todos' ? nc.tienda : estadoOrdenAccent(nc, valor);
          return ChoiceChip(
            label: Text(label),
            selected: sel,
            showCheckmark: false,
            onSelected: (_) => onSelect(valor),
            selectedColor: accent.fill,
            backgroundColor: nc.bgGlass,
            side: BorderSide(color: sel ? accent.fill : nc.border),
            labelStyle: AppTypography.labelMedium(
                    color: sel ? accent.onFill : nc.textPrimary)
                .copyWith(fontWeight: FontWeight.w600),
          );
        },
      ),
    );
  }
}
