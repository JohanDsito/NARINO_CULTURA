import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/nc_theme.dart';
import 'nc_buttons.dart';
import 'nc_card.dart';

/// Estado vacío / error dentro de una tarjeta: ícono con acento, título,
/// mensaje y acción opcional.
class NcEmptyState extends StatelessWidget {
  const NcEmptyState({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 0),
  });

  final IconData icon;
  final NcAccent accent;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: padding,
      child: NcCard(
        child: Column(
          children: [
            NcAccentIcon(icon: icon, accent: accent, size: 64, glow: true),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTypography.displaySemiBold(color: nc.textPrimary)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(color: nc.textSecondary)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              NcPrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

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

/// Píldora de estado con el color de un acento (relleno o tinte).
class NcStatusPill extends StatelessWidget {
  const NcStatusPill({
    super.key,
    required this.label,
    required this.accent,
    this.filled = false,
    this.icon,
  });

  final String label;
  final NcAccent accent;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? accent.onFill : accent.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? accent.fill : accent.tint,
        borderRadius: BorderRadius.circular(99),
        border: filled
            ? null
            : Border.all(color: accent.fill.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(color: fg)
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
