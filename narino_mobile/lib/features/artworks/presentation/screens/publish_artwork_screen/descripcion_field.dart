import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'field_padding.dart';

class DescripcionField extends StatelessWidget {
  const DescripcionField({
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
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      style: AppTypography.bodyMedium(color: textPrimary),
      decoration: const InputDecoration(
        labelText: 'Descripción',
        alignLabelWithHint: true,
        contentPadding: kFieldPadding,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 56),
          child: Icon(Icons.description_outlined),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
