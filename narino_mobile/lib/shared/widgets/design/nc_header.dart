import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/nc_theme.dart';
import 'nc_pressable.dart';

/// Logo: cuadro de 34 px, radio 10, "N" sobre degradado naranja → magenta.
class NcBrandMark extends StatelessWidget {
  const NcBrandMark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: context.nc.brandGradient,
        borderRadius: BorderRadius.circular(size * 10 / 34),
      ),
      child: Text(
        'N',
        style: TextStyle(
          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.5,
          height: 1,
        ),
      ),
    );
  }
}

/// Marca completa: logo + "Nariño Cultura" (+ subtítulo opcional).
class NcBrand extends StatelessWidget {
  const NcBrand({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Semantics(
      label: 'Nariño Cultura',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NcBrandMark(),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nariño Cultura',
                style: TextStyle(
                  fontFamily: family,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.48,
                  height: 1.15,
                  color: nc.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: family,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: nc.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

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
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: title ?? const NcBrand(),
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
