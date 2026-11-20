import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class ProfileStat extends StatelessWidget {
  const ProfileStat(
      {super.key, required this.valor, required this.label, this.onTap});

  final String valor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Expanded(
      child: NcPressable(
        onTap: onTap,
        semanticLabel: '$valor $label',
        child: Column(
          children: [
            Text(valor,
                style: AppTypography.displaySemiBold(color: nc.textPrimary)),
            Text(label,
                style: AppTypography.bodySmall(color: nc.textSecondary)),
          ],
        ),
      ),
    );
  }
}
