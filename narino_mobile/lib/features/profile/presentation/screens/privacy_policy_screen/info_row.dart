import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: '$label: ',
                  style: AppTypography.labelSemiBold(color: textPrimary)
                      .copyWith(fontSize: 12)),
              TextSpan(
                  text: value,
                  style: AppTypography.bodySmall(color: textSecondary)),
            ],
          ),
        ),
      );
}
