import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/artwork_model.dart';

/// Contadores por estado (todas, disponibles, en subasta, vendidas) que
/// además filtran la cuadrícula.
class MisObrasFiltros extends StatelessWidget {
  const MisObrasFiltros({
    super.key,
    required this.obras,
    required this.filtro,
    required this.onFiltro,
  });

  final List<ArtworkModel> obras;

  /// Estado elegido; `null` = todas.
  final String? filtro;
  final ValueChanged<String?> onFiltro;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    int contar(String e) => obras.where((a) => a.estado == e).length;
    final stats = <(String?, String, int, NcAccent)>[
      (null, 'Todas', obras.length, nc.catalogo),
      ('disponible', 'Disponibles', contar('disponible'), nc.successA),
      ('en_subasta', 'En subasta', contar('en_subasta'), nc.subastas),
      ('vendida', 'Vendidas', contar('vendida'), nc.tomateA),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (estado, label, cantidad, accent) = stats[i];
          final sel = filtro == estado;
          return Semantics(
            selected: sel,
            button: true,
            label: '$label: $cantidad',
            excludeSemantics: true,
            child: NcPressable(
              onTap: () => onFiltro(estado),
              pressedScale: 0.95,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 108,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sel ? accent.fill : nc.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: sel ? accent.fill : nc.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$cantidad',
                        style: AppTypography.displayBold(
                            color: sel ? accent.onFill : accent.ink)),
                    Text(label,
                        style: AppTypography.bodySmall(
                            color: sel ? accent.onFill : nc.textSecondary)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
