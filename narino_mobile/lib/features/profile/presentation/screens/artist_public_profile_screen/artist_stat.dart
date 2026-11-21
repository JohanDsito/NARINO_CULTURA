import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

class ArtistStat extends StatelessWidget {
  const ArtistStat({super.key, required this.valor, required this.label});

  final String valor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor,
              style: AppTypography.displaySemiBold(color: nc.textPrimary)),
          Text(label, style: AppTypography.bodySmall(color: nc.textSecondary)),
        ],
      ),
    );
  }
}
