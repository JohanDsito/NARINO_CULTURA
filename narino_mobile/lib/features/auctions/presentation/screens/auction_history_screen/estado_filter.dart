import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Constantes ───────────────────────────────────────────────────────────────

const _kEstados = <String?, String>{
  null: 'Todos',
  'activa': 'Activa',
  'cerrada': 'Cerrada',
  'cancelada': 'Cancelada',
};

// ─── Filtro de estado ─────────────────────────────────────────────────────────

class EstadoFilter extends StatelessWidget {
  const EstadoFilter({super.key, required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final selectedBg =
        isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(Icons.filter_list_outlined, size: 18, color: textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _kEstados.entries.map((entry) {
                  final isSelected = value == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        entry.value,
                        style: AppTypography.caption(
                          color: isSelected ? cs.primary : textMuted,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => onChanged(entry.key),
                      backgroundColor: bgSubtle,
                      selectedColor: selectedBg,
                      checkmarkColor: Colors.transparent,
                      side: BorderSide(
                        color: isSelected ? cs.primary : border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
