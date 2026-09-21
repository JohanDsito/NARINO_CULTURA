import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'contact_channel.dart';

// ─── Sección 8: Canales de contacto ──────────────────────────────────────────

class ContactSection extends StatelessWidget {
  const ContactSection({
    super.key,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.cs,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final ColorScheme cs;

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'privacidad@nariniocultura.edu.co',
      queryParameters: {
        'subject': 'Solicitud de derechos ARCO — [Tipo de solicitud]',
        'body':
            'Nombre completo: \nCorreo registrado: \nTipo de solicitud: \nDescripción: ',
      },
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.selvaAndina.withValues(alpha: 0.4)),
        color: AppColors.selvaAndina.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.selvaAndina.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent_outlined, color: AppColors.selvaAndina, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sección 8. Canales para Ejercer tus Derechos',
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
                ContactChannel(
                  icon: Icons.mail_outline,
                  title: 'Correo electrónico',
                  subtitle: 'privacidad@nariniocultura.edu.co\nAsunto: "Solicitud de derechos ARCO — [Tipo]"',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                ContactChannel(
                  icon: Icons.chat_outlined,
                  title: 'Chat de soporte',
                  subtitle: 'Disponible en la Plataforma para consultas generales sobre tratamiento de datos.',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                ContactChannel(
                  icon: Icons.language_outlined,
                  title: 'Formulario web',
                  subtitle: 'Pie de página de la plataforma web → "Política de Privacidad → Ejercer mis derechos".',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  'Para tramitar tu solicitud necesitarás: nombre completo, correo electrónico registrado y descripción clara del derecho que deseas ejercer.',
                  style: AppTypography.caption(color: textSecondary),
                ),
                const SizedBox(height: 16),

                // Botón principal CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _launchEmail,
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: const Text('Ejercer mis derechos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.selvaAndina,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
