import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import 'privacy_policy_screen/policy_bullet.dart';
import 'privacy_policy_screen/policy_channels_section.dart';
import 'privacy_policy_screen/policy_intro.dart';
import 'privacy_policy_screen/policy_rights_section.dart';
import 'privacy_policy_screen/politica_contacto.dart';
import 'privacy_policy_screen/policy_info_row.dart';
import 'privacy_policy_screen/policy_paragraph.dart';
import 'privacy_policy_screen/policy_section.dart';
import 'privacy_policy_screen/policy_subtitle.dart';

/// Política de privacidad. El texto legal se conserva tal cual; aquí solo
/// cambia la presentación (secciones plegables, derechos y canales a la vista).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const PolicyIntro(),
          const PolicySection(
            numero: 1,
            titulo: 'Responsable del Tratamiento',
            children: [
              PolicyParagraph(
                  'El responsable del tratamiento es el equipo de desarrollo del proyecto '
                  'Nariño Cultura, conformado por estudiantes del programa de Ingeniería '
                  'de Software de la Universidad Cooperativa de Colombia, sede San Juan de '
                  'Pasto, Nariño.'),
              SizedBox(height: 10),
              PolicyInfoRow('Proyecto', 'Nariño Cultura'),
              PolicyInfoRow('Institución',
                  'Universidad Cooperativa de Colombia — Sede Pasto'),
              PolicyInfoRow('Correo de contacto', kCorreoPrivacidad),
              PolicyInfoRow('Dirección',
                  'Calle 11 # 6-08, San Juan de Pasto, Nariño, Colombia'),
            ],
          ),
          const PolicySection(
            numero: 2,
            titulo: 'Marco Legal Aplicable',
            children: [
              PolicyBullet(
                  'Ley 1581 de 2012 — Ley Estatutaria de Protección de Datos Personales.'),
              PolicyBullet(
                  'Decreto 1074 de 2015 — Decreto Único Reglamentario del Sector Comercio.'),
              PolicyBullet(
                  'Ley 1266 de 2008 — Disposiciones generales sobre Hábeas Data.'),
              PolicyBullet(
                  'Circular Única de la SIC — Instrucciones sobre tratamiento de información personal.'),
            ],
          ),
          const PolicySection(
            numero: 3,
            titulo: 'Autorización para el Tratamiento',
            children: [
              PolicyParagraph(
                  'El consentimiento expreso se recoge mediante un checkbox obligatorio '
                  'en el formulario de registro. El usuario no puede crear una cuenta '
                  'sin haber aceptado expresamente esta política.'),
            ],
          ),
          const PolicySection(
            numero: 4,
            titulo: 'Datos Recolectados y Finalidades',
            children: [
              PolicySubtitle('Datos de Identificación (todos los usuarios)'),
              PolicyBullet(
                  'Nombre completo y nombre artístico: identificación dentro de la Plataforma.'),
              PolicyBullet(
                  'Correo electrónico: gestión de cuenta y notificaciones.'),
              PolicyBullet('Contraseña (hash cifrado): autenticación segura.'),
              PolicyBullet('Teléfono (opcional): contacto en transacciones.'),
              PolicySubtitle('Datos del Perfil Artístico (artistas)'),
              PolicyBullet(
                  'Fotografía de perfil y obras: exhibición pública en catálogo.'),
              PolicyBullet('Biografía y trayectoria: presentación al público.'),
              PolicyBullet(
                  'Disciplina y técnicas: categorización en el catálogo.'),
              PolicySubtitle('Datos de Transacciones'),
              PolicyBullet(
                  'Historial de compras/ventas: gestión de órdenes y comprobantes.'),
              PolicyBullet(
                  'Datos de pago: procesados por pasarela (Wompi). La Plataforma NO almacena datos de tarjetas.'),
              PolicySubtitle('Datos de Navegación'),
              PolicyBullet(
                  'Visualizaciones de obras: se cuenta el total de vistas de cada obra para ordenar el catálogo y mostrar estadísticas al artista. Para no contar dos veces la misma visita, se recuerda durante una hora que ya viste esa obra; no queda guardado en la base de datos.'),
              PolicyBullet(
                  'Dirección IP: se registra junto con las acciones que crean, modifican o eliminan información, por seguridad y auditoría.'),
            ],
          ),
          const PolicySection(
            numero: 5,
            titulo: 'Tiempo de Conservación',
            children: [
              PolicyBullet(
                  'Datos de cuenta activa: durante toda la vigencia de la cuenta.'),
              PolicyBullet(
                  'Al eliminar la cuenta se borran de inmediato tu perfil, tus obras, tus favoritos, tu carrito y tu historial de compras.'),
              PolicyBullet(
                  'El registro de seguridad (acción realizada e IP) se conserva sin asociarse a tu cuenta.'),
            ],
          ),
          const PolicyRightsSection(),
          const PolicyChannelsSection(),
          const PolicySection(
            numero: 8,
            titulo: 'Medidas de Seguridad',
            children: [
              PolicyBullet(
                  'Autenticación con tokens JWT firmados (HS256): el acceso dura 30 minutos y la sesión se renueva hasta por 7 días.'),
              PolicyBullet(
                  'Contraseñas almacenadas con Argon2 (nunca en texto plano).'),
              PolicyBullet('Comunicaciones cifradas mediante HTTPS/TLS.'),
              PolicyBullet(
                  'Control de acceso por roles (artista, comprador, gestor, administrador).'),
              PolicyBullet(
                  'Protección contra inyección SQL mediante ORM de Django.'),
              PolicyBullet(
                  'Límite de 5 intentos por minuto para iniciar sesión o registrarse, y de 3 solicitudes por hora para recuperar la contraseña.'),
            ],
          ),
          const PolicySection(
            numero: 9,
            titulo: 'Transferencia a Terceros',
            children: [
              PolicyBullet(
                  'Pasarela de pagos (Wompi): para procesar transacciones.'),
              PolicyBullet(
                  'Proveedor de correo: envío de notificaciones transaccionales.'),
              PolicyBullet(
                  'Infraestructura cloud (Railway): alojamiento con garantías de seguridad.'),
              PolicyBullet(
                  'Proveedor de IA (Google Gemini): el texto que escribes al asistente y los datos de la obra (título, técnica, materiales) cuando pides una descripción con IA. No se envían tu nombre, correo ni teléfono.'),
              SizedBox(height: 8),
              PolicyParagraph(
                  'La Plataforma NO vende, alquila ni comparte datos personales con fines comerciales.'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Nariño Cultura · Versión 1.1 · San Juan de Pasto, Nariño, 2026\n'
            'Universidad Cooperativa de Colombia · Ingeniería de Software',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: nc.textMuted),
          ),
        ],
      ),
    );
  }
}
