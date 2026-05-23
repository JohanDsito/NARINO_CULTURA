import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Privacidad',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Encabezado
          Center(
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield_outlined, color: cs.primary, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  'Política de Privacidad',
                  style: AppTypography.displaySemiBold(color: textPrimary)
                      .copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Nariño Cultura · Versión 1.0 · 2026',
                  style: AppTypography.caption(color: textMuted),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Universidad Cooperativa de Colombia',
                  style: AppTypography.caption(color: textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sección 1 — Responsable
          _Section(
            title: 'Sección 1. Responsable del Tratamiento',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              _Body(
                'El responsable del tratamiento es el equipo de desarrollo del proyecto '
                'Nariño Cultura, conformado por estudiantes del programa de Ingeniería '
                'de Software de la Universidad Cooperativa de Colombia, sede San Juan de '
                'Pasto, Nariño.',
                color: textSecondary,
              ),
              const SizedBox(height: 10),
              _InfoRow(label: 'Proyecto', value: 'Nariño Cultura', textPrimary: textPrimary, textSecondary: textSecondary),
              _InfoRow(label: 'Institución', value: 'Universidad Cooperativa de Colombia — Sede Pasto', textPrimary: textPrimary, textSecondary: textSecondary),
              _InfoRow(label: 'Correo de contacto', value: 'privacidad@nariniocultura.edu.co', textPrimary: textPrimary, textSecondary: textSecondary),
              _InfoRow(label: 'Dirección', value: 'Calle 11 # 6-08, San Juan de Pasto, Nariño, Colombia', textPrimary: textPrimary, textSecondary: textSecondary),
            ],
          ),

          // Sección 2 — Marco legal
          _Section(
            title: 'Sección 2. Marco Legal Aplicable',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              _Bullet('Ley 1581 de 2012 — Ley Estatutaria de Protección de Datos Personales.', color: textSecondary),
              _Bullet('Decreto 1074 de 2015 — Decreto Único Reglamentario del Sector Comercio.', color: textSecondary),
              _Bullet('Ley 1266 de 2008 — Disposiciones generales sobre Hábeas Data.', color: textSecondary),
              _Bullet('Circular Única de la SIC — Instrucciones sobre tratamiento de información personal.', color: textSecondary),
            ],
          ),

          // Sección 3 — Autorización
          _Section(
            title: 'Sección 3. Autorización para el Tratamiento',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              _Body(
                'El consentimiento expreso se recoge mediante un checkbox obligatorio '
                'en el formulario de registro. El usuario no puede crear una cuenta '
                'sin haber aceptado expresamente esta política. La fecha y hora de '
                'aceptación quedan registradas para fines de auditoría.',
                color: textSecondary,
              ),
            ],
          ),

          // Sección 4 — Datos recolectados
          _Section(
            title: 'Sección 4. Datos Recolectados y Finalidades',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              _SubTitle('Datos de Identificación (todos los usuarios)', color: textPrimary),
              _Bullet('Nombre completo y nombre artístico: identificación dentro de la Plataforma.', color: textSecondary),
              _Bullet('Correo electrónico: gestión de cuenta y notificaciones.', color: textSecondary),
              _Bullet('Contraseña (hash cifrado): autenticación segura.', color: textSecondary),
              _Bullet('Teléfono (opcional): contacto en transacciones.', color: textSecondary),
              const SizedBox(height: 8),
              _SubTitle('Datos del Perfil Artístico (artistas)', color: textPrimary),
              _Bullet('Fotografía de perfil y obras: exhibición pública en catálogo.', color: textSecondary),
              _Bullet('Biografía y trayectoria: presentación al público.', color: textSecondary),
              _Bullet('Disciplina y técnicas: categorización en el catálogo.', color: textSecondary),
              const SizedBox(height: 8),
              _SubTitle('Datos de Transacciones', color: textPrimary),
              _Bullet('Historial de compras/ventas: gestión de órdenes y comprobantes.', color: textSecondary),
              _Bullet('Datos de pago: procesados por pasarela (Wompi). La Plataforma NO almacena datos de tarjetas.', color: textSecondary),
              const SizedBox(height: 8),
              _SubTitle('Datos de Navegación', color: textPrimary),
              _Bullet('Historial de visualización: recomendaciones personalizadas con IA.', color: textSecondary),
              _Bullet('Dispositivo y SO: compatibilidad y optimización.', color: textSecondary),
              _Bullet('IP y ubicación aproximada: seguridad y estadísticas regionales.', color: textSecondary),
            ],
          ),

          // Sección 6 — Conservación
          _Section(
            title: 'Sección 6. Tiempo de Conservación',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              _Bullet('Datos de cuenta activa: durante toda la vigencia de la cuenta.', color: textSecondary),
              _Bullet('Datos de transacciones: mínimo 5 años desde la fecha de transacción.', color: textSecondary),
              _Bullet('Tras eliminar la cuenta: datos de identificación eliminados en máximo 30 días naturales.', color: textSecondary),
            ],
          ),

          // ─── Sección 7 — DERECHOS DEL TITULAR (destacada) ─────────────────
          _RightsSection(
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            cs: cs,
          ),

          // ─── Sección 8 — CANALES DE CONTACTO (destacada) ──────────────────
          _ContactSection(
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            border: border,
            cs: cs,
          ),

          // Sección 9 — Medidas de seguridad
          _Section(
            title: 'Sección 9. Medidas de Seguridad',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              _Bullet('Autenticación con tokens JWT cifrados (HS256), expiración de 15 minutos.', color: textSecondary),
              _Bullet('Contraseñas almacenadas con bcrypt (nunca en texto plano).', color: textSecondary),
              _Bullet('Comunicaciones cifradas mediante HTTPS/TLS.', color: textSecondary),
              _Bullet('Control de acceso por roles (artista, comprador, gestor, administrador).', color: textSecondary),
              _Bullet('Protección contra inyección SQL mediante ORM de Django.', color: textSecondary),
              _Bullet('Bloqueo tras 5 intentos fallidos de inicio de sesión (15 minutos).', color: textSecondary),
            ],
          ),

          // Sección 10 — Transferencia a terceros
          _Section(
            title: 'Sección 10. Transferencia a Terceros',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              _Bullet('Pasarela de pagos (Wompi): para procesar transacciones.', color: textSecondary),
              _Bullet('Proveedor de correo: envío de notificaciones transaccionales.', color: textSecondary),
              _Bullet('Infraestructura cloud (Railway): alojamiento con garantías de seguridad.', color: textSecondary),
              _Bullet('Proveedor de IA (OpenAI / Gemini): datos de navegación anonimizados para recomendaciones. Sin datos de identificación personal.', color: textSecondary),
              const SizedBox(height: 8),
              _Body('La Plataforma NO vende, alquila ni comparte datos personales con fines comerciales.', color: textSecondary),
            ],
          ),

          const SizedBox(height: 32),

          // Pie
          Center(
            child: Text(
              'Nariño Cultura · Versión 1.0 · San Juan de Pasto, Nariño, 2026\nUniversidad Cooperativa de Colombia · Ingeniería de Software',
              style: AppTypography.caption(color: textMuted),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Sección 7: Derechos del titular ─────────────────────────────────────────

class _RightsSection extends StatelessWidget {
  const _RightsSection({
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
                _RightRow(icon: Icons.search_outlined, cs: cs, right: 'Conocer', desc: 'Solicitar qué datos tuyos son tratados y con qué finalidad.', textPrimary: textPrimary, textSecondary: textSecondary),
                _RightRow(icon: Icons.edit_outlined, cs: cs, right: 'Actualizar', desc: 'Solicitar la corrección de datos desactualizados o incompletos.', textPrimary: textPrimary, textSecondary: textSecondary),
                _RightRow(icon: Icons.edit_note_outlined, cs: cs, right: 'Rectificar', desc: 'Solicitar la corrección de errores en tus datos personales.', textPrimary: textPrimary, textSecondary: textSecondary),
                _RightRow(icon: Icons.delete_outline, cs: cs, right: 'Suprimir', desc: 'Solicitar la eliminación de tus datos cuando no sean necesarios.', textPrimary: textPrimary, textSecondary: textSecondary),
                _RightRow(icon: Icons.undo_outlined, cs: cs, right: 'Revocar', desc: 'Retirar el consentimiento otorgado en cualquier momento.', textPrimary: textPrimary, textSecondary: textSecondary),
                _RightRow(icon: Icons.folder_open_outlined, cs: cs, right: 'Acceder', desc: 'Obtener copia de los datos que obran en nuestras bases de datos.', textPrimary: textPrimary, textSecondary: textSecondary),
                _RightRow(icon: Icons.gavel_outlined, cs: cs, right: 'Presentar quejas', desc: 'Elevar consultas ante la Superintendencia de Industria y Comercio (SIC).', textPrimary: textPrimary, textSecondary: textSecondary),
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

class _RightRow extends StatelessWidget {
  const _RightRow({
    required this.icon,
    required this.cs,
    required this.right,
    required this.desc,
    required this.textPrimary,
    required this.textSecondary,
  });

  final IconData icon;
  final ColorScheme cs;
  final String right;
  final String desc;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$right: ',
                    style: AppTypography.labelSemiBold(color: textPrimary)
                        .copyWith(fontSize: 13),
                  ),
                  TextSpan(
                    text: desc,
                    style: AppTypography.bodySmall(color: textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sección 8: Canales de contacto ──────────────────────────────────────────

class _ContactSection extends StatelessWidget {
  const _ContactSection({
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
                _ContactChannel(
                  icon: Icons.mail_outline,
                  title: 'Correo electrónico',
                  subtitle: 'privacidad@nariniocultura.edu.co\nAsunto: "Solicitud de derechos ARCO — [Tipo]"',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _ContactChannel(
                  icon: Icons.chat_outlined,
                  title: 'Chat de soporte',
                  subtitle: 'Disponible en la Plataforma para consultas generales sobre tratamiento de datos.',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _ContactChannel(
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

class _ContactChannel extends StatelessWidget {
  const _ContactChannel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.textPrimary,
    required this.textSecondary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.selvaAndina, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.labelSemiBold(color: textPrimary)
                        .copyWith(fontSize: 13)),
                Text(subtitle,
                    style: AppTypography.bodySmall(color: textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Componentes reutilizables ────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.bgSubtle,
  });

  final String title;
  final List<Widget> children;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color bgSubtle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.labelSemiBold(color: textPrimary)
                  .copyWith(fontSize: 14)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  const _SubTitle(this.text, {required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: AppTypography.labelSemiBold(color: color).copyWith(fontSize: 12)),
      );
}

class _Body extends StatelessWidget {
  const _Body(this.text, {required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.bodySmall(color: color));
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, {required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AppTypography.bodySmall(color: color))),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: '$label: ',
                  style: AppTypography.labelSemiBold(color: textPrimary)
                      .copyWith(fontSize: 12)),
              TextSpan(
                  text: value,
                  style: AppTypography.bodySmall(color: textSecondary)),
            ],
          ),
        ),
      );
}
