import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

class PolicyBullet extends StatelessWidget {
  const PolicyBullet(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 10),
            width: 5,
            height: 5,
            decoration:
                BoxDecoration(color: nc.textMuted, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(text,
                style: AppTypography.bodyMedium(color: nc.textSecondary)),
          ),
        ],
      ),
    );
  }
}
