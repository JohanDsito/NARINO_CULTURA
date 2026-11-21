import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/nc_theme.dart';
import 'nc_tab_bar/nc_tab_button.dart';
import 'nc_tab_bar/nc_tab_item.dart';

export 'nc_tab_bar/nc_tab_item.dart';

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
                  child: NcTabButton(
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
