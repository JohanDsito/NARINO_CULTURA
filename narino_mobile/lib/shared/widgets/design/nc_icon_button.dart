import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/nc_theme.dart';
import 'nc_pressable.dart';

/// Botón redondo de 44 px con borde (`.icon-btn`), con contador opcional.
class NcIconButton extends StatelessWidget {
  const NcIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.badge = 0,
    this.bordered = true,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final int badge;
  final bool bordered;
  final double size;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Tooltip(
      message: tooltip,
      child: NcPressable(
        onTap: onPressed,
        pressedScale: 0.9,
        semanticLabel: badge > 0 ? '$tooltip, $badge nuevas' : tooltip,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: bordered ? Border.all(color: nc.border) : null,
                  ),
                  child: Icon(icon,
                      size: bordered ? 20 : 24, color: nc.textPrimary),
                ),
              ),
              if (badge > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.tomate,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: nc.bg, width: 2),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
