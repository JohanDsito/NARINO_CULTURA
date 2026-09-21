import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'field_padding.dart';

class TituloField extends StatelessWidget {
  const TituloField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      style: AppTypography.bodyMedium(color: textPrimary),
      decoration: const InputDecoration(
        labelText: 'Título de la obra *',
        prefixIcon: Icon(Icons.title),
        contentPadding: kFieldPadding,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null,
      onChanged: onChanged,
    );
  }
}
