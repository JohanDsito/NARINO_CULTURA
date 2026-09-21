import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'privacy_policy_screen/body.dart';
import 'privacy_policy_screen/bullet.dart';
import 'privacy_policy_screen/contact_section.dart';
import 'privacy_policy_screen/info_row.dart';
import 'privacy_policy_screen/rights_section.dart';
import 'privacy_policy_screen/section.dart';
import 'privacy_policy_screen/sub_title.dart';

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
          PolicySection(
            title: 'Sección 1. Responsable del Tratamiento',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              PolicyBody(
                'El responsable del tratamiento es el equipo de desarrollo del proyecto '
                'Nariño Cultura, conformado por estudiantes del programa de Ingeniería '
                'de Software de la Universidad Cooperativa de Colombia, sede San Juan de '
                'Pasto, Nariño.',
                color: textSecondary,
              ),
              const SizedBox(height: 10),
              InfoRow(label: 'Proyecto', value: 'Nariño Cultura', textPrimary: textPrimary, textSecondary: textSecondary),
              InfoRow(label: 'Institución', value: 'Universidad Cooperativa de Colombia — Sede Pasto', textPrimary: textPrimary, textSecondary: textSecondary),
              InfoRow(label: 'Correo de contacto', value: 'privacidad@nariniocultura.edu.co', textPrimary: textPrimary, textSecondary: textSecondary),
              InfoRow(label: 'Dirección', value: 'Calle 11 # 6-08, San Juan de Pasto, Nariño, Colombia', textPrimary: textPrimary, textSecondary: textSecondary),
            ],
          ),

          // Sección 2 — Marco legal
          PolicySection(
            title: 'Sección 2. Marco Legal Aplicable',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              Bullet('Ley 1581 de 2012 — Ley Estatutaria de Protección de Datos Personales.', color: textSecondary),
              Bullet('Decreto 1074 de 2015 — Decreto Único Reglamentario del Sector Comercio.', color: textSecondary),
              Bullet('Ley 1266 de 2008 — Disposiciones generales sobre Hábeas Data.', color: textSecondary),
              Bullet('Circular Única de la SIC — Instrucciones sobre tratamiento de información personal.', color: textSecondary),
            ],
          ),

          // Sección 3 — Autorización
          PolicySection(
            title: 'Sección 3. Autorización para el Tratamiento',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              PolicyBody(
                'El consentimiento expreso se recoge mediante un checkbox obligatorio '
                'en el formulario de registro. El usuario no puede crear una cuenta '
                'sin haber aceptado expresamente esta política. La fecha y hora de '
                'aceptación quedan registradas para fines de auditoría.',
                color: textSecondary,
              ),
            ],
          ),

          // Sección 4 — Datos recolectados
          PolicySection(
            title: 'Sección 4. Datos Recolectados y Finalidades',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              SubTitle('Datos de Identificación (todos los usuarios)', color: textPrimary),
              Bullet('Nombre completo y nombre artístico: identificación dentro de la Plataforma.', color: textSecondary),
              Bullet('Correo electrónico: gestión de cuenta y notificaciones.', color: textSecondary),
              Bullet('Contraseña (hash cifrado): autenticación segura.', color: textSecondary),
              Bullet('Teléfono (opcional): contacto en transacciones.', color: textSecondary),
              const SizedBox(height: 8),
              SubTitle('Datos del Perfil Artístico (artistas)', color: textPrimary),
              Bullet('Fotografía de perfil y obras: exhibición pública en catálogo.', color: textSecondary),
              Bullet('Biografía y trayectoria: presentación al público.', color: textSecondary),
              Bullet('Disciplina y técnicas: categorización en el catálogo.', color: textSecondary),
              const SizedBox(height: 8),
              SubTitle('Datos de Transacciones', color: textPrimary),
              Bullet('Historial de compras/ventas: gestión de órdenes y comprobantes.', color: textSecondary),
              Bullet('Datos de pago: procesados por pasarela (Wompi). La Plataforma NO almacena datos de tarjetas.', color: textSecondary),
              const SizedBox(height: 8),
              SubTitle('Datos de Navegación', color: textPrimary),
              Bullet('Historial de visualización: recomendaciones personalizadas con IA.', color: textSecondary),
              Bullet('Dispositivo y SO: compatibilidad y optimización.', color: textSecondary),
              Bullet('IP y ubicación aproximada: seguridad y estadísticas regionales.', color: textSecondary),
            ],
          ),

          // Sección 6 — Conservación
          PolicySection(
            title: 'Sección 6. Tiempo de Conservación',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              Bullet('Datos de cuenta activa: durante toda la vigencia de la cuenta.', color: textSecondary),
              Bullet('Datos de transacciones: mínimo 5 años desde la fecha de transacción.', color: textSecondary),
              Bullet('Tras eliminar la cuenta: datos de identificación eliminados en máximo 30 días naturales.', color: textSecondary),
            ],
          ),

          // ─── Sección 7 — DERECHOS DEL TITULAR (destacada) ─────────────────
          RightsSection(
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            cs: cs,
          ),

          // ─── Sección 8 — CANALES DE CONTACTO (destacada) ──────────────────
          ContactSection(
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            border: border,
            cs: cs,
          ),

          // Sección 9 — Medidas de seguridad
          PolicySection(
            title: 'Sección 9. Medidas de Seguridad',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              Bullet('Autenticación con tokens JWT cifrados (HS256), expiración de 15 minutos.', color: textSecondary),
              Bullet('Contraseñas almacenadas con bcrypt (nunca en texto plano).', color: textSecondary),
              Bullet('Comunicaciones cifradas mediante HTTPS/TLS.', color: textSecondary),
              Bullet('Control de acceso por roles (artista, comprador, gestor, administrador).', color: textSecondary),
              Bullet('Protección contra inyección SQL mediante ORM de Django.', color: textSecondary),
              Bullet('Bloqueo tras 5 intentos fallidos de inicio de sesión (15 minutos).', color: textSecondary),
            ],
          ),

          // Sección 10 — Transferencia a terceros
          PolicySection(
            title: 'Sección 10. Transferencia a Terceros',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
            bgSubtle: bgSubtle,
            children: [
              Bullet('Pasarela de pagos (Wompi): para procesar transacciones.', color: textSecondary),
              Bullet('Proveedor de correo: envío de notificaciones transaccionales.', color: textSecondary),
              Bullet('Infraestructura cloud (Railway): alojamiento con garantías de seguridad.', color: textSecondary),
              Bullet('Proveedor de IA (OpenAI / Gemini): datos de navegación anonimizados para recomendaciones. Sin datos de identificación personal.', color: textSecondary),
              const SizedBox(height: 8),
              PolicyBody('La Plataforma NO vende, alquila ni comparte datos personales con fines comerciales.', color: textSecondary),
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
