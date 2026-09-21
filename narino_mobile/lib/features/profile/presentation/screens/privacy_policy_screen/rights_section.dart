import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import 'right_row.dart';

// ─── Sección 7: Derechos del titular ─────────────────────────────────────────

class RightsSection extends StatelessWidget {
  const RightsSection({
    super.key,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.cs,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
        color: cs.primary.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sección 7. Derechos del Titular',
                    style: AppTypography.labelSemiBold(color: textPrimary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conforme a los artículos 8 y 9 de la Ley 1581 de 2012, tienes los siguientes derechos frente al tratamiento de tus datos:',
                  style: AppTypography.bodySmall(color: textSecondary),
                ),
                const SizedBox(height: 12),
                RightRow(icon: Icons.search_outlined, cs: cs, right: 'Conocer', desc: 'Solicitar qué datos tuyos son tratados y con qué finalidad.', textPrimary: textPrimary, textSecondary: textSecondary),
                RightRow(icon: Icons.edit_outlined, cs: cs, right: 'Actualizar', desc: 'Solicitar la corrección de datos desactualizados o incompletos.', textPrimary: textPrimary, textSecondary: textSecondary),
                RightRow(icon: Icons.edit_note_outlined, cs: cs, right: 'Rectificar', desc: 'Solicitar la corrección de errores en tus datos personales.', textPrimary: textPrimary, textSecondary: textSecondary),
                RightRow(icon: Icons.delete_outline, cs: cs, right: 'Suprimir', desc: 'Solicitar la eliminación de tus datos cuando no sean necesarios.', textPrimary: textPrimary, textSecondary: textSecondary),
                RightRow(icon: Icons.undo_outlined, cs: cs, right: 'Revocar', desc: 'Retirar el consentimiento otorgado en cualquier momento.', textPrimary: textPrimary, textSecondary: textSecondary),
                RightRow(icon: Icons.folder_open_outlined, cs: cs, right: 'Acceder', desc: 'Obtener copia de los datos que obran en nuestras bases de datos.', textPrimary: textPrimary, textSecondary: textSecondary),
                RightRow(icon: Icons.gavel_outlined, cs: cs, right: 'Presentar quejas', desc: 'Elevar consultas ante la Superintendencia de Industria y Comercio (SIC).', textPrimary: textPrimary, textSecondary: textSecondary),
                const SizedBox(height: 8),
                Text(
                  'El ejercicio de estos derechos no tiene ningún costo. Plazos de respuesta: 10 días hábiles para consultas y 15 días hábiles para reclamaciones.',
                  style: AppTypography.caption(color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
