import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/nc_theme.dart';

/// Barra inferior de vidrio para acciones fijas (total + botón, etc.).
class NcGlassBottomBar extends StatelessWidget {
  const NcGlassBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          decoration: BoxDecoration(
            color: nc.bgGlass,
            border: Border(top: BorderSide(color: nc.border)),
          ),
          child: child,
        ),
      ),
    );
  }
}
