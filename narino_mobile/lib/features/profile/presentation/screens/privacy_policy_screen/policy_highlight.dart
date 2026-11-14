import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class PolicyHighlight extends StatelessWidget {
  const PolicyHighlight(
      {super.key,
      required this.icon,
      required this.accent,
      required this.text});

  final IconData icon;
  final NcAccent accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NcAccentIcon(icon: icon, accent: accent, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(text,
                  style: AppTypography.bodyMedium(color: nc.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}
