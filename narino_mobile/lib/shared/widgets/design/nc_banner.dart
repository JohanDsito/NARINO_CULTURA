import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/nc_theme.dart';

/// Aviso en línea con el color de un acento (error, éxito, info…).
class NcBanner extends StatelessWidget {
  const NcBanner({
    super.key,
    required this.message,
    required this.accent,
    this.icon = Icons.info_outline_rounded,
  });

  /// Atajo para errores (tomate).
  factory NcBanner.error(BuildContext context, String message) => NcBanner(
        message: message,
        accent: context.nc.tomateA,
        icon: Icons.error_outline_rounded,
      );

  /// Atajo para confirmaciones (verde).
  factory NcBanner.success(BuildContext context, String message) => NcBanner(
        message: message,
        accent: context.nc.successA,
        icon: Icons.check_circle_outline_rounded,
      );

  final String message;
  final NcAccent accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: accent.tint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.fill.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent.ink, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium(color: nc.textPrimary)
                    .copyWith(fontSize: 13.5, height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
