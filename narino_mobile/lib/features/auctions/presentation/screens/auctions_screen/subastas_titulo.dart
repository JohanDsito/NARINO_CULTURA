import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

class SubastasTitulo extends StatelessWidget {
  const SubastasTitulo(this.text, this.trailing, {super.key});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: AppTypography.displayBold(color: nc.textPrimary)),
          ),
          if (trailing != null)
            Text(trailing!,
                style: AppTypography.labelMedium(color: nc.textSecondary)),
        ],
      ),
    );
  }
}
