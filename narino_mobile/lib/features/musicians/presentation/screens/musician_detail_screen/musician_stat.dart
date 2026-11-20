import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

class MusicianStat extends StatelessWidget {
  const MusicianStat(
      {super.key,
      required this.valor,
      required this.label,
      this.estrella = false});

  final String valor;
  final String label;
  final bool estrella;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(valor,
                  style: AppTypography.displaySemiBold(color: nc.textPrimary)),
              if (estrella) ...[
                const SizedBox(width: 2),
                Icon(Icons.star_rounded, size: 18, color: nc.oro),
              ],
            ],
          ),
          Text(label, style: AppTypography.bodySmall(color: nc.textSecondary)),
        ],
      ),
    );
  }
}
