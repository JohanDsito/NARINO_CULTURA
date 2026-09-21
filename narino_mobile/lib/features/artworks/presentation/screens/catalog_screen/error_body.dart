import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/artwork_state.dart';
import '../../providers/artwork_provider.dart';

class ErrorBody extends ConsumerWidget {
  const ErrorBody({super.key, required this.state});

  final ArtworkState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // ✅ FIX: ícono usaba AppColors.textMutedLight hardcodeado
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ FIX: color del ícono resuelto desde el tema
              Icon(Icons.cloud_off_outlined, size: 48, color: textMuted),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'Ha ocurrido un error',
                style: AppTypography.bodyMedium(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(artworkProvider.notifier).loadCatalog(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                // ✅ FIX: estilo del botón resuelto desde el tema
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
