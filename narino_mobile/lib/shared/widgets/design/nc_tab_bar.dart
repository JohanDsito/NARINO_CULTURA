import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/nc_theme.dart';
import 'nc_pressable.dart';

class NcTabItem {
  const NcTabItem({required this.label, required this.icon, this.activeIcon});
  final String label;
  final IconData icon;
  final IconData? activeIcon;
}

/// Barra inferior de vidrio (`.tabbar`): 64 px + zona segura, desenfoque 24,
/// borde superior. La pestaña activa va en azul neón.
class NcTabBar extends StatelessWidget {
  const NcTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NcTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: height + bottom,
          padding: EdgeInsets.fromLTRB(4, 0, 4, bottom),
          decoration: BoxDecoration(
            color: nc.bgGlass,
            border: Border(top: BorderSide(color: nc.border)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _Tab(
                    item: items[i],
                    active: i == currentIndex,
                    reduce: reduce,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
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
    final duration =
        reduce ? Duration.zero : const Duration(milliseconds: 400);

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
