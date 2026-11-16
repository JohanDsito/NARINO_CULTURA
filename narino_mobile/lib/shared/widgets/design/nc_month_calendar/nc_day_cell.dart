import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../nc_pressable.dart';

class NcDayCell extends StatelessWidget {
  const NcDayCell({
    super.key,
    required this.label,
    this.muted = false,
    this.active = false,
    this.today = false,
    this.hasEvent = false,
    this.semantics,
    this.onTap,
  });

  final String label;
  final bool muted;
  final bool active;
  final bool today;
  final bool hasEvent;
  final String? semantics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fg = active ? nc.onAzul : nc.textPrimary;
    final cell = Opacity(
      opacity: muted ? 0.3 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? nc.azul : Colors.transparent,
          border: today && !active
              ? Border.all(color: nc.azul.withValues(alpha: 0.6))
              : null,
          boxShadow: active && nc.isDark
              ? [
                  BoxShadow(
                    color: AppColors.azulNeon.withValues(alpha: 0.4),
                    blurRadius: 15,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              label,
              style: AppTypography.labelMedium(color: fg).copyWith(
                fontSize: 14,
                fontWeight: active || today ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (hasEvent)
              Positioned(
                bottom: 5,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? fg : nc.naranja,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap == null) return ExcludeSemantics(child: cell);
    return Semantics(
      label: semantics,
      selected: active,
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: NcPressable(onTap: onTap, pressedScale: 0.88, child: cell),
    );
  }
}
