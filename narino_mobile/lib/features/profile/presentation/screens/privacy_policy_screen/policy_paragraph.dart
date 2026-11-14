import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

class PolicyParagraph extends StatelessWidget {
  const PolicyParagraph(this.text, {super.key, this.pequeno = false});

  final String text;
  final bool pequeno;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Text(text,
        style: pequeno
            ? AppTypography.bodySmall(color: nc.textSecondary)
            : AppTypography.bodyMedium(color: nc.textSecondary));
  }
}
