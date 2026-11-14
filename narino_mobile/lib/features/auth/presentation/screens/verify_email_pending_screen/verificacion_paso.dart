import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

class VerificacionPaso extends StatelessWidget {
  const VerificacionPaso(
      {super.key,
      required this.number,
      required this.text,
      required this.accent});

  final int number;
  final String text;
  final NcAccent accent;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: accent.fill, shape: BoxShape.circle),
          child: Text(
            '$number',
            style: AppTypography.labelSemiBold(color: accent.onFill)
                .copyWith(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text,
                style: AppTypography.bodyMedium(color: nc.textPrimary)),
          ),
        ),
      ],
    );
  }
}
