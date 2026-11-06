import 'dart:ui';

import 'package:flutter/material.dart';

import 'nc_pressable.dart';

/// Botón circular de vidrio para usar sobre imágenes (volver, favorito,
/// compartir…). Fondo negro translúcido con desenfoque y borde blanco sutil.
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = Colors.white,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: NcPressable(
          onTap: onPressed,
          pressedScale: 0.88,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Icon(icon, size: 21, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
