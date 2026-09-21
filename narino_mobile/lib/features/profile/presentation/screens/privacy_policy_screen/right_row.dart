import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class RightRow extends StatelessWidget {
  const RightRow({
    super.key,
    required this.icon,
    required this.cs,
    required this.right,
    required this.desc,
    required this.textPrimary,
    required this.textSecondary,
  });

  final IconData icon;
  final ColorScheme cs;
  final String right;
  final String desc;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$right: ',
                    style: AppTypography.labelSemiBold(color: textPrimary)
                        .copyWith(fontSize: 13),
                  ),
                  TextSpan(
                    text: desc,
                    style: AppTypography.bodySmall(color: textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
