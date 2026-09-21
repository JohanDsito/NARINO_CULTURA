import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

// ✅ FIX: FilterLabel recibe color como parámetro en lugar de hardcodear
// AppColors.textSecondaryLight, que rompía el dark mode
class FilterLabel extends StatelessWidget {
  const FilterLabel(this.text, {super.key, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelMedium(color: color),
    );
  }
}
