import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/artwork_model.dart';
import 'field_padding.dart';

class TecnicaDropdown extends StatelessWidget {
  const TecnicaDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return DropdownButtonFormField<String?>(
      initialValue: value,
      style: AppTypography.bodyMedium(color: textPrimary),
      dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      hint: Text(
        'Técnica (opcional)',
        style: AppTypography.bodyMedium(color: textMuted),
      ),
      items: [
        const DropdownMenuItem<String?>(
            value: null, child: Text('Sin especificar')),
        ...kTecnicasNarino
            .map((t) => DropdownMenuItem(value: t, child: Text(t))),
      ],
      onChanged: onChanged,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.brush_outlined),
        contentPadding: kFieldPadding,
      ),
    );
  }
}
