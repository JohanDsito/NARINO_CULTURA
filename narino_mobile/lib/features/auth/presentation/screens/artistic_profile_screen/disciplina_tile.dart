import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../profile/presentation/widgets/disciplinas.dart';

class DisciplinaTile extends StatelessWidget {
  const DisciplinaTile({
    super.key,
    required this.disciplina,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final Disciplina disciplina;
  final NcAccent accent;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '${disciplina.label}. ${disciplina.description}',
      onTap: onTap,
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(accent.tint, nc.bgCard)
                : nc.itemFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent.fill : nc.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? accent.fill : accent.tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  disciplina.icon,
                  size: 22,
                  color: selected ? accent.onFill : accent.ink,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disciplina.label,
                      style: AppTypography.labelSemiBold(
                          color: selected ? accent.ink : nc.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      disciplina.description,
                      style: AppTypography.bodySmall(color: nc.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? accent.fill : Colors.transparent,
                  border: Border.all(
                    color: selected ? accent.fill : nc.textMuted,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: 14, color: accent.onFill)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
