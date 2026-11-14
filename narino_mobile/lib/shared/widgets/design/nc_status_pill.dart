import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/nc_theme.dart';

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
