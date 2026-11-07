import 'package:flutter/material.dart';

import '../../../../../core/theme/nc_theme.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Vista de error ───────────────────────────────────────────────────────────

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final textSecondary = nc.textSecondary;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Detalle',
          style: AppTypography.displaySemiBold(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: nc.tomateA.ink,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTypography.bodyMedium(color: textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
