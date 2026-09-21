import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/artwork_state.dart';
import '../../providers/artwork_provider.dart';

class EmptyBody extends ConsumerWidget {
  const EmptyBody({super.key, required this.state});

  final ArtworkState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 70),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ FIX: antes usaba `border` como color de ícono — semánticamente
              // incorrecto. Ahora usa textMuted que es el token correcto para
              // íconos decorativos en estado vacío.
              Icon(Icons.palette_outlined, size: 56, color: textMuted),
              const SizedBox(height: 14),
              Text(
                'No se encontraron obras',
                style: AppTypography.bodyMedium(color: textMuted),
              ),
              if (state.hayFiltrosActivos) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () =>
                      ref.read(artworkProvider.notifier).limpiarFiltros(),
                  icon: Icon(
                    Icons.filter_alt_off_outlined,
                    size: 18,
                    // ✅ FIX: color del ícono resuelto desde el tema
                    color: cs.primary,
                  ),
                  label: Text(
                    'Limpiar filtros',
                    style: AppTypography.bodySmall(color: cs.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
