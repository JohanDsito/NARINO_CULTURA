import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/nc_theme.dart';
import 'nc_pressable.dart';

/// Tarjeta del design system (`.card-container`): radio 22, borde de 1 px.
/// En modo oscuro el borde es un degradado neón azul → naranja.
class NcCard extends StatelessWidget {
  const NcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 22,
    this.onTap,
    this.gradientBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  /// Permite desactivar el borde degradado (p. ej. listas muy largas).
  final bool gradientBorder;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final outer = BorderRadius.circular(radius);
    final Widget card;

    if (nc.isDark && gradientBorder) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          gradient: nc.borderGradient,
          borderRadius: outer,
          boxShadow: nc.shadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: nc.bgCard,
              borderRadius: BorderRadius.circular(radius - 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 1),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      );
    } else {
      card = DecoratedBox(
        decoration: BoxDecoration(
          color: nc.bgCard,
          borderRadius: outer,
          border: Border.all(color: nc.border),
          boxShadow: nc.isDark ? nc.shadow : null,
        ),
        child: ClipRRect(
          borderRadius: outer,
          child: Padding(padding: padding, child: child),
        ),
      );
    }

    return onTap == null
        ? card
        : NcPressable(onTap: onTap, pressedScale: 0.98, child: card);
  }
}

/// Encabezado de sección (`.section-header h2`): 24/800, -0.03em.
class NcSectionHeader extends StatelessWidget {
  const NcSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title,
                  style: AppTypography.displayBold(color: nc.textPrimary)),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
