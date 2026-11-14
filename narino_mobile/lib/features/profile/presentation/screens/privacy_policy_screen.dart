import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import 'privacy_policy_screen/policy_bullet.dart';
import 'privacy_policy_screen/policy_contact_channel.dart';
import 'privacy_policy_screen/policy_highlight.dart';
import 'privacy_policy_screen/policy_info_row.dart';
import 'privacy_policy_screen/policy_paragraph.dart';
import 'privacy_policy_screen/policy_right_row.dart';
import 'privacy_policy_screen/policy_section.dart';
import 'privacy_policy_screen/policy_subtitle.dart';

const _kCorreo = 'privacidad@nariniocultura.edu.co';

/// Política de privacidad. El texto legal se conserva tal cual; aquí solo
/// cambia la presentación (secciones plegables, derechos y canales a la vista).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _escribir(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _kCorreo,
      queryParameters: {
        'subject': 'Solicitud de derechos ARCO — [Tipo de solicitud]',
        'body':
            'Nombre completo: \nCorreo registrado: \nTipo de solicitud: \nDescripción: ',
      },
    );
    // canLaunchUrl('mailto:') da false en Android 11+ sin <queries>: se
    // intenta abrir directo y, si no hay app de correo, se copia la dirección.
    var abierto = false;
    try {
      abierto = await launchUrl(uri);
    } catch (_) {}
    if (abierto || !context.mounted) return;
    await Clipboard.setData(const ClipboardData(text: _kCorreo));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No encontramos una app de correo. Copiamos la '
            'dirección para que la pegues.')));
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Encabezado ──
          Column(
            children: [
              NcAccentIcon(
                  icon: Icons.shield_outlined,
                  accent: nc.successA,
                  size: 60,
                  glow: true),
              const SizedBox(height: 14),
              Text('Política de Privacidad',
                  textAlign: TextAlign.center,
                  style: AppTypography.displayBold(color: nc.textPrimary)
                      .copyWith(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                  'Nariño Cultura · Versión 1.1 · 2026\n'
                  'Universidad Cooperativa de Colombia',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall(color: nc.textMuted)),
              const SizedBox(height: 12),
              const NcSerpentina(width: 56),
            ],
          ),
          const SizedBox(height: 20),

          // ── Lo esencial (frases tomadas de la política) ──
          NcCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lo esencial',
                    style: AppTypography.displaySemiBold(color: nc.textPrimary)
                        .copyWith(fontSize: 17)),
                const SizedBox(height: 8),
                PolicyHighlight(
                    icon: Icons.block_rounded,
                    accent: nc.successA,
                    text: 'La Plataforma NO vende, alquila ni comparte datos '
                        'personales con fines comerciales.'),
                PolicyHighlight(
                    icon: Icons.credit_card_off_outlined,
                    accent: nc.tienda,
                    text: 'Los pagos los procesa Wompi. La Plataforma NO '
                        'almacena datos de tarjetas.'),
                PolicyHighlight(
                    icon: Icons.verified_user_outlined,
                    accent: nc.azulA,
                    text:
                        'El ejercicio de tus derechos no tiene ningún costo.'),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
              PolicyInfoRow('Correo de contacto', _kCorreo),
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

          // ── Sección 7: derechos, siempre a la vista ──
          PolicySection(
            numero: 6,
            titulo: 'Derechos del Titular',
            accent: nc.catalogo,
            abierta: true,
            children: [
              const PolicyParagraph(
                  'Conforme a los artículos 8 y 9 de la Ley 1581 de 2012, tienes los '
                  'siguientes derechos frente al tratamiento de tus datos:'),
              const SizedBox(height: 10),
              for (final (icon, derecho, desc) in const [
                (
                  Icons.search_outlined,
                  'Conocer',
                  'Solicitar qué datos tuyos son tratados y con qué finalidad.'
                ),
                (
                  Icons.edit_outlined,
                  'Actualizar',
                  'Solicitar la corrección de datos desactualizados o incompletos.'
                ),
                (
                  Icons.edit_note_outlined,
                  'Rectificar',
                  'Solicitar la corrección de errores en tus datos personales.'
                ),
                (
                  Icons.delete_outline,
                  'Suprimir',
                  'Solicitar la eliminación de tus datos cuando no sean necesarios.'
                ),
                (
                  Icons.undo_outlined,
                  'Revocar',
                  'Retirar el consentimiento otorgado en cualquier momento.'
                ),
                (
                  Icons.folder_open_outlined,
                  'Acceder',
                  'Obtener copia de los datos que obran en nuestras bases de datos.'
                ),
                (
                  Icons.gavel_outlined,
                  'Presentar quejas',
                  'Elevar consultas ante la Superintendencia de Industria y Comercio (SIC).'
                ),
              ])
                PolicyRightRow(icon: icon, derecho: derecho, desc: desc),
              const SizedBox(height: 6),
              const PolicyParagraph(
                  'El ejercicio de estos derechos no tiene ningún costo. Plazos de '
                  'respuesta: 10 días hábiles para consultas y 15 días hábiles para '
                  'reclamaciones.',
                  pequeno: true),
            ],
          ),

          // ── Sección 8: canales ──
          PolicySection(
            numero: 7,
            titulo: 'Canales para Ejercer tus Derechos',
            accent: nc.azulA,
            abierta: true,
            children: [
              PolicyContactChannel(
                icon: Icons.mail_outline,
                accent: nc.azulA,
                titulo: 'Correo electrónico',
                texto:
                    '$_kCorreo\nAsunto: "Solicitud de derechos ARCO — [Tipo]"',
                onTap: () => _escribir(context),
              ),
              PolicyContactChannel(
                icon: Icons.chat_outlined,
                accent: nc.catalogo,
                titulo: 'Chat de soporte',
                texto:
                    'Disponible en la Plataforma para consultas generales sobre '
                    'tratamiento de datos.',
                onTap: () => context.push('/chatbot'),
              ),
              PolicyContactChannel(
                icon: Icons.language_outlined,
                accent: nc.oroA,
                titulo: 'Formulario web',
                texto: 'Pie de página de la plataforma web → "Política de '
                    'Privacidad → Ejercer mis derechos".',
              ),
              const SizedBox(height: 6),
              const PolicyParagraph(
                  'Para tramitar tu solicitud necesitarás: nombre completo, correo '
                  'electrónico registrado y descripción clara del derecho que deseas '
                  'ejercer.',
                  pequeno: true),
              const SizedBox(height: 14),
              NcPrimaryButton(
                label: 'Ejercer mis derechos',
                icon: Icons.send_outlined,
                onPressed: () => _escribir(context),
              ),
            ],
          ),

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
