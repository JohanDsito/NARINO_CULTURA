import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

/// Opción de rol en el registro (tarjeta seleccionable con su color).
class RoleOption extends StatelessWidget {
  const RoleOption({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String description;
  final NcAccent accent;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$title. $description',
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(accent.tint, nc.bgCard)
                : nc.itemFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent.fill : nc.border,
              width: selected ? 1.6 : 1,
            ),
            boxShadow:
                selected && nc.isDark ? nc.tintedShadow(accent.fill) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: accent.fill,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded,
                          size: 15, color: accent.onFill),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: AppTypography.labelSemiBold(
                    color: selected ? accent.ink : nc.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.bodySmall(
                    color: selected
                        ? nc.textPrimary.withValues(alpha: 0.85)
                        : nc.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
