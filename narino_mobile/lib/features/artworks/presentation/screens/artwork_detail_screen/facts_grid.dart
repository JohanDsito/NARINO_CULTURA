import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../domain/artwork_model.dart';

/// Ficha técnica en grilla de 2 columnas con íconos.
class FactsGrid extends StatelessWidget {
  const FactsGrid({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final facts = <(IconData, String, String, NcAccent)>[
      if (artwork.categoria.isNotEmpty)
        (Icons.category_outlined, 'Categoría', artwork.categoria, nc.catalogo),
      if ((artwork.tecnica ?? '').isNotEmpty)
        (Icons.brush_outlined, 'Técnica', artwork.tecnica!, nc.naranjaA),
      if ((artwork.dimensiones ?? '').isNotEmpty)
        (
          Icons.straighten_rounded,
          'Dimensiones',
          artwork.dimensiones!,
          nc.azulA
        ),
      if (artwork.anio != null)
        (Icons.event_outlined, 'Año', '${artwork.anio}', nc.oroA),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ficha técnica',
            style: AppTypography.displaySemiBold(color: nc.textPrimary)),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final w = (c.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final f in facts)
                SizedBox(
                  width: w,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: nc.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: nc.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(f.$1, size: 20, color: f.$4.ink),
                        const SizedBox(height: 10),
                        Text(f.$2,
                            style: AppTypography.bodySmall(
                                color: nc.textSecondary)),
                        const SizedBox(height: 2),
                        Text(f.$3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSemiBold(
                                    color: nc.textPrimary)
                                .copyWith(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}
