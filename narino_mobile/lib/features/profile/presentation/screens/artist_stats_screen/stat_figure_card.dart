import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class StatFigureCard extends StatelessWidget {
  const StatFigureCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.valor,
    required this.label,
  });

  final IconData icon;
  final NcAccent accent;
  final String valor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Semantics(
      label: '$valor $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: nc.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: nc.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NcAccentIcon(icon: icon, accent: accent, size: 34),
            const SizedBox(height: 12),
            Text(valor,
                style: AppTypography.displayBold(color: nc.textPrimary)
                    .copyWith(fontSize: 26)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 2,
                style: AppTypography.bodySmall(color: nc.textSecondary)),
          ],
        ),
      ),
    );
  }
}
