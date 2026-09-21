import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Vista de error ───────────────────────────────────────────────────────────

class ErrorScaffold extends StatelessWidget {
  const ErrorScaffold({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Evento',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 48,
                color: muted,
              ),
              const SizedBox(height: 14),
              Text(
                'No se pudo cargar el evento',
                style: AppTypography.bodyMedium(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: AppTypography.bodySmall(color: muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
