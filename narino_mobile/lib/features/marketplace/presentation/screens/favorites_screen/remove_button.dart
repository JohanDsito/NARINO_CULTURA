import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

// ─── Botón de quitar favorito ─────────────────────────────────────────────────

class RemoveButton extends StatelessWidget {
  const RemoveButton({super.key, required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.bgCardDark.withValues(alpha: 0.92)
        : Colors.white.withAlpha(92);
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.favorite,
          color: AppColors.error,
          size: 17,
        ),
      ),
    );
  }
}
