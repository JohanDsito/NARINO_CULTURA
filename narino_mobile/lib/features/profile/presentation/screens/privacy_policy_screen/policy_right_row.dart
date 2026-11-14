import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

class PolicyRightRow extends StatelessWidget {
  const PolicyRightRow(
      {super.key,
      required this.icon,
      required this.derecho,
      required this.desc});

  final IconData icon;
  final String derecho;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = nc.catalogo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: a.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: '$derecho. ',
                    style: AppTypography.labelSemiBold(color: nc.textPrimary)),
                TextSpan(
                    text: desc,
                    style: AppTypography.bodyMedium(color: nc.textSecondary)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
