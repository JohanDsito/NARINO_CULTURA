import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/artwork_model.dart';
import 'field_padding.dart';

class CategoriaDropdown extends StatelessWidget {
  const CategoriaDropdown({
    super.key,
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<CategoryModel> categories;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    // Si la categoría seleccionada ya no está en la lista (cargando), se ignora
    final validValue =
        categories.any((c) => c.id == value) ? value : null;

    return DropdownButtonFormField<int>(
      initialValue: validValue,
      style: AppTypography.bodyMedium(color: textPrimary),
      dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      hint: categories.isEmpty
          ? Text('Cargando categorías…',
              style: AppTypography.bodyMedium(color: textMuted))
          : Text('Categoría artística *',
              style: AppTypography.bodyMedium(color: textMuted)),
      items: categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selecciona una categoría' : null,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.category_outlined),
        contentPadding: kFieldPadding,
      ),
    );
  }
}
