import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'field_padding.dart';

class DimensionesRow extends StatelessWidget {
  const DimensionesRow({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return TextFormField(
      controller: controller,
      style: AppTypography.bodyMedium(color: textPrimary),
      decoration: const InputDecoration(
        labelText: 'Dimensiones (opcional)',
        hintText: '50x70 cm',
        prefixIcon: Icon(Icons.straighten_outlined),
        contentPadding: kFieldPadding,
      ),
    );
  }
}
