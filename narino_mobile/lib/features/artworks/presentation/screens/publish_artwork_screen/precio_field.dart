import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'field_padding.dart';

class PrecioField extends StatelessWidget {
  const PrecioField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: AppTypography.bodyMedium(color: textPrimary),
      decoration: const InputDecoration(
        labelText: 'Precio en COP',
        hintText: 'Ingresa 0 si es para exhibición',
        prefixIcon: Icon(Icons.sell_outlined),
        prefixText: r'$ ',
        contentPadding: kFieldPadding,
      ),
      validator: (v) {
        if (v != null && v.trim().isNotEmpty) {
          final n = double.tryParse(v.trim());
          if (n == null || n < 0) return 'Ingresa un precio válido';
        }
        return null;
      },
    );
  }
}
