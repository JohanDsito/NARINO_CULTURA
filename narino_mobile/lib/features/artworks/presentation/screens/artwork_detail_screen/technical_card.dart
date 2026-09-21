import 'package:flutter/material.dart';

import '../../../domain/artwork_model.dart';
import 'info_row.dart';
import 'section_card.dart';

class TechnicalCard extends StatelessWidget {
  const TechnicalCard({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      InfoRow('Categoría', artwork.categoria),
      if (artwork.tecnica != null) InfoRow('Técnica', artwork.tecnica!),
      if (artwork.dimensiones != null)
        InfoRow('Dimensiones', artwork.dimensiones!),
      if (artwork.anio != null) InfoRow('Año', artwork.anio.toString()),
    ];

    return SectionCard(
      title: 'Ficha técnica',
      icon: Icons.info_outline,
      child: Column(children: rows),
    );
  }
}
