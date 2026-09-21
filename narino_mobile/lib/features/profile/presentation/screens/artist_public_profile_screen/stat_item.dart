import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class StatItem extends StatelessWidget {
  const StatItem({
    super.key,
    required this.value,
    required this.label,
    required this.textPrimary,
    required this.textMuted,
  });

  final String value;
  final String label;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTypography.displaySemiBold(color: textPrimary)
                .copyWith(fontSize: 20)),
        Text(label, style: AppTypography.caption(color: textMuted)),
      ],
    );
  }
}
