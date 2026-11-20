import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/nc_theme.dart';
import 'nc_brand.dart';

/// Header de vidrio (`header`): fondo translúcido con desenfoque 20 y borde
/// inferior. Se usa con `Scaffold(extendBodyBehindAppBar: true)` para que el
/// contenido pase por detrás.
class NcGlassHeader extends StatelessWidget implements PreferredSizeWidget {
  const NcGlassHeader({
    super.key,
    this.leading,
    this.title,
    this.actions = const [],
  });

  /// Contenido a la izquierda; por defecto la marca.
  final Widget? leading;
  final Widget? title;
  final List<Widget> actions;

  static const double contentHeight = 68; // 12 + 44 + 12

  @override
  Size get preferredSize => const Size.fromHeight(contentHeight);

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: nc.bgGlass,
            border: Border(bottom: BorderSide(color: nc.border)),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: contentHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (leading != null) leading!,
                    if (leading != null && title != null)
                      const SizedBox(width: 8),
                    Expanded(
                      // Altura fija (68): con letra grande el título se
                      // encoge en vez de desbordarse.
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: title ?? const NcBrand(),
                        ),
                      ),
                    ),
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
