import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.label, required this.textMuted});
  final String label;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTypography.labelSemiBold(color: textMuted)
            .copyWith(fontSize: 13));
  }
}
