import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

class VentasStat extends StatelessWidget {
  const VentasStat(
      {super.key,
      required this.label,
      required this.value,
      required this.accent});

  final String label;
  final String value;
  final NcAccent accent;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypography.displaySemiBold(color: accent.ink)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodySmall(color: nc.textSecondary)),
      ],
    );
  }
}
