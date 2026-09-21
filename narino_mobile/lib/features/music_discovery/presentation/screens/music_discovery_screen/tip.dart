import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class Tip extends StatelessWidget {
  const Tip({
    super.key,
    required this.icon,
    required this.text,
    required this.textMuted,
  });

  final IconData icon;
  final String text;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: AppTypography.bodySmall(color: textMuted)),
        ),
      ],
    );
  }
}
