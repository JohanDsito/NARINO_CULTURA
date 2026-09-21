import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'example_chip.dart';

class EmptyChat extends StatelessWidget {
  const EmptyChat({super.key, required this.onExampleTap});

  final void Function(String text) onExampleTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, color: textMuted, size: 72),
            const SizedBox(height: 16),
            Text(
              'Pregúntame sobre arte y cultura de Nariño',
              style: AppTypography.displaySemiBold(
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ejemplos: “¿Qué obras hay en Barniz de Pasto?” o “¿Qué eventos hay esta semana?”',
              style: AppTypography.bodySmall(color: textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ExampleChip(
                  label: 'Carnaval',
                  onTap: () => onExampleTap(
                    'Cuéntame sobre el Carnaval de Negros y Blancos.',
                  ),
                ),
                ExampleChip(
                  label: 'Artistas',
                  onTap: () => onExampleTap(
                    '¿Qué artistas destacados hay en la plataforma?',
                  ),
                ),
                ExampleChip(
                  label: 'Eventos',
                  onTap: () => onExampleTap(
                    'Recomiéndame eventos culturales en Nariño.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
