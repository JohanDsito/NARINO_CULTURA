import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class StatColumn extends StatelessWidget {
  const StatColumn({
    super.key,
    required this.label,
    required this.labelColor,
    required this.value,
    required this.valueStyle,
    this.icon,
  });

  final String label;
  final Color labelColor;
  final String value;
  final TextStyle valueStyle;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption(color: labelColor)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 4)],
            Text(value, style: valueStyle),
          ],
        ),
      ],
    );
  }
}
