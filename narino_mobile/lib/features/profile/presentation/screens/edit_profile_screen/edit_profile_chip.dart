import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class EditProfileChip extends StatelessWidget {
  const EditProfileChip({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.icon,
    this.check = false,
  });

  final String label;
  final bool selected;
  final NcAccent accent;
  final VoidCallback onTap;
  final IconData? icon;
  final bool check;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fg = selected ? accent.onFill : nc.textPrimary;
    final leading = check && selected ? Icons.check_rounded : icon;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? accent.fill : nc.itemFill,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? accent.fill : nc.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Icon(leading,
                    size: 16, color: selected ? accent.onFill : accent.ink),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: AppTypography.labelMedium(color: fg)
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
