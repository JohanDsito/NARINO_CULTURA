import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── URL del flyer ──────────────────────────────────────────────────────────
//
// El backend guarda el flyer del evento como una URL de texto (Event.image_url
// es un URLField), no como un archivo subido — no existe un endpoint para
// subir imágenes de eventos. Por eso este campo pide un enlace ya alojado en
// vez de elegir una foto del dispositivo.

class FlyerPicker extends StatelessWidget {
  const FlyerPicker({
    super.key,
    required this.controller,
    required this.disabled,
  });

  final TextEditingController controller;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined, size: 16, color: textMuted),
            const SizedBox(width: 6),
            Text(
              'Flyer / imagen (opcional)',
              style: AppTypography.labelSemiBold(color: textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: !disabled,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://...',
            prefixIcon: Icon(Icons.link_outlined),
          ),
          validator: (v) {
            final value = v?.trim() ?? '';
            if (value.isEmpty) return null;
            final uri = Uri.tryParse(value);
            if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
              return 'Ingresa una URL válida';
            }
            return null;
          },
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final url = value.text.trim();
            if (url.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: bgSubtle,
                    alignment: Alignment.center,
                    child: Icon(Icons.broken_image_outlined,
                        color: textMuted, size: 32),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: bgSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
