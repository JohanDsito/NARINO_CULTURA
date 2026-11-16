import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class NotificationFilterChip extends StatelessWidget {
  const NotificationFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = nc.azulA;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? a.fill : nc.itemFill,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? a.fill : nc.border),
          ),
          child: Text(label,
              style: AppTypography.labelMedium(
                      color: selected ? a.onFill : nc.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
