import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'tip.dart';

// ─── Suggestion chips ─────────────────────────────────────────────────────────

const _kSuggestions = [
  'Música andina de Nariño',
  'Chirimía del Pacífico',
  'Cumbia nariñense',
  'Trova pastusa',
  'Rock alternativo Pasto',
  'Jazz fusión andino',
];

class SuggestionsPanel extends StatelessWidget {
  const SuggestionsPanel({
    super.key,
    required this.textPrimary,
    required this.textMuted,
    required this.onSuggestion,
  });

  final Color textPrimary;
  final Color textMuted;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Búsquedas sugeridas',
              style: AppTypography.labelSemiBold(color: textPrimary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kSuggestions.map((s) {
                return ActionChip(
                  label: Text(s,
                      style: AppTypography.caption(
                          color: AppColors.indigoClaro)),
                  onPressed: () => onSuggestion(s),
                  backgroundColor:
                      AppColors.indigoClaro.withValues(alpha: 0.1),
                  side: BorderSide(
                      color: AppColors.indigoClaro.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined,
                    size: 16, color: AppColors.indigoClaro),
                const SizedBox(width: 6),
                Text('Consejos', style: AppTypography.labelSemiBold(color: textPrimary)),
              ],
            ),
            const SizedBox(height: 10),
            Tip(
              icon: Icons.music_note_outlined,
              text:
                  'Describe el género, ritmo o estado de ánimo que buscas.',
              textMuted: textMuted,
            ),
            const SizedBox(height: 8),
            Tip(
              icon: Icons.place_outlined,
              text:
                  'Menciona una ciudad o región de Nariño para resultados locales.',
              textMuted: textMuted,
            ),
            const SizedBox(height: 8),
            Tip(
              icon: Icons.people_outline,
              text:
                  'Indica si buscas solistas, dúos o agrupaciones musicales.',
              textMuted: textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
