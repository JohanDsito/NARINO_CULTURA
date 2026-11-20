import 'package:flutter/material.dart';
import '../../../core/theme/nc_theme.dart';

/// Ícono dentro de un círculo teñido con el color del acento.
class NcAccentIcon extends StatelessWidget {
  const NcAccentIcon({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 44,
    this.glow = false,
  });

  final IconData icon;
  final NcAccent accent;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.tint,
        shape: BoxShape.circle,
        border: Border.all(color: accent.fill.withValues(alpha: 0.4)),
        boxShadow: glow ? nc.tintedShadow(accent.fill) : null,
      ),
      child: Icon(icon, color: accent.ink, size: size * 0.48),
    );
  }
}
