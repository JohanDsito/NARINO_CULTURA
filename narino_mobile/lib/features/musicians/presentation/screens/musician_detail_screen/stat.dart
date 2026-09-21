import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class Stat extends StatelessWidget {
  const Stat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppTypography.labelSemiBold(color: color)),
            Text(label, style: AppTypography.caption(color: color)),
          ],
        ),
      ],
    );
  }
}
