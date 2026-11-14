import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../nc_pressable.dart';
import 'nc_tab_item.dart';

class NcTabButton extends StatelessWidget {
  const NcTabButton({
    super.key,
    required this.item,
    required this.active,
    required this.reduce,
    required this.onTap,
  });

  final NcTabItem item;
  final bool active;
  final bool reduce;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final color = active ? nc.azul : nc.textSecondary;
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 400);

    return Semantics(
      selected: active,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.88,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSlide(
                offset: Offset(0, active ? -0.05 : 0),
                duration: duration,
                curve: kNcSpring,
                child: Icon(
                  active ? (item.activeIcon ?? item.icon) : item.icon,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: duration,
                style: AppTypography.caption(color: color),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
