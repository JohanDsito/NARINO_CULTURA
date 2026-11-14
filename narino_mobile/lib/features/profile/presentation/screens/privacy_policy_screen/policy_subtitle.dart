import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

class PolicySubtitle extends StatelessWidget {
  const PolicySubtitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child:
          Text(text, style: AppTypography.labelSemiBold(color: nc.textPrimary)),
    );
  }
}
