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
