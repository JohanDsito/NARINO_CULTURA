import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

class PolicyInfoRow extends StatelessWidget {
  const PolicyInfoRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySmall(color: nc.textMuted)),
          const SizedBox(height: 2),
          SelectableText(value,
              style: AppTypography.bodyMedium(color: nc.textPrimary)),
        ],
      ),
    );
  }
}
