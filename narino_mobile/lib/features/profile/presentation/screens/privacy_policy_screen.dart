import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';

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
                _Punto(
                    icon: Icons.block_rounded,
                    accent: nc.successA,
                    text: 'La Plataforma NO vende, alquila ni comparte datos '
                        'personales con fines comerciales.'),
                _Punto(
                    icon: Icons.credit_card_off_outlined,
                    accent: nc.tienda,
                    text: 'Los pagos los procesa Wompi. La Plataforma NO '
                        'almacena datos de tarjetas.'),
                _Punto(
                    icon: Icons.verified_user_outlined,
                    accent: nc.azulA,
                    text:
                        'El ejercicio de tus derechos no tiene ningún costo.'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const _Seccion(
            numero: 1,
            titulo: 'Responsable del Tratamiento',
            children: [
              _Parrafo(
                  'El responsable del tratamiento es el equipo de desarrollo del proyecto '
                  'Nariño Cultura, conformado por estudiantes del programa de Ingeniería '
                  'de Software de la Universidad Cooperativa de Colombia, sede San Juan de '
                  'Pasto, Nariño.'),
              SizedBox(height: 10),
              _Dato('Proyecto', 'Nariño Cultura'),
              _Dato('Institución',
                  'Universidad Cooperativa de Colombia — Sede Pasto'),
              _Dato('Correo de contacto', _kCorreo),
              _Dato('Dirección',
                  'Calle 11 # 6-08, San Juan de Pasto, Nariño, Colombia'),
            ],
          ),
          const _Seccion(
            numero: 2,
            titulo: 'Marco Legal Aplicable',
            children: [
              _Vineta(
                  'Ley 1581 de 2012 — Ley Estatutaria de Protección de Datos Personales.'),
              _Vineta(
                  'Decreto 1074 de 2015 — Decreto Único Reglamentario del Sector Comercio.'),
              _Vineta(
                  'Ley 1266 de 2008 — Disposiciones generales sobre Hábeas Data.'),
              _Vineta(
                  'Circular Única de la SIC — Instrucciones sobre tratamiento de información personal.'),
            ],
          ),
          const _Seccion(
            numero: 3,
            titulo: 'Autorización para el Tratamiento',
            children: [
              _Parrafo(
                  'El consentimiento expreso se recoge mediante un checkbox obligatorio '
                  'en el formulario de registro. El usuario no puede crear una cuenta '
                  'sin haber aceptado expresamente esta política.'),
            ],
          ),
          const _Seccion(
            numero: 4,
            titulo: 'Datos Recolectados y Finalidades',
            children: [
              _Subtitulo('Datos de Identificación (todos los usuarios)'),
              _Vineta(
                  'Nombre completo y nombre artístico: identificación dentro de la Plataforma.'),
              _Vineta(
                  'Correo electrónico: gestión de cuenta y notificaciones.'),
              _Vineta('Contraseña (hash cifrado): autenticación segura.'),
              _Vineta('Teléfono (opcional): contacto en transacciones.'),
              _Subtitulo('Datos del Perfil Artístico (artistas)'),
              _Vineta(
                  'Fotografía de perfil y obras: exhibición pública en catálogo.'),
              _Vineta('Biografía y trayectoria: presentación al público.'),
              _Vineta('Disciplina y técnicas: categorización en el catálogo.'),
              _Subtitulo('Datos de Transacciones'),
              _Vineta(
                  'Historial de compras/ventas: gestión de órdenes y comprobantes.'),
              _Vineta(
                  'Datos de pago: procesados por pasarela (Wompi). La Plataforma NO almacena datos de tarjetas.'),
              _Subtitulo('Datos de Navegación'),
              _Vineta(
                  'Visualizaciones de obras: se cuenta el total de vistas de cada obra para ordenar el catálogo y mostrar estadísticas al artista. Para no contar dos veces la misma visita, se recuerda durante una hora que ya viste esa obra; no queda guardado en la base de datos.'),
              _Vineta(
                  'Dirección IP: se registra junto con las acciones que crean, modifican o eliminan información, por seguridad y auditoría.'),
            ],
          ),
          const _Seccion(
            numero: 5,
            titulo: 'Tiempo de Conservación',
            children: [
              _Vineta(
                  'Datos de cuenta activa: durante toda la vigencia de la cuenta.'),
              _Vineta(
                  'Al eliminar la cuenta se borran de inmediato tu perfil, tus obras, tus favoritos, tu carrito y tu historial de compras.'),
              _Vineta(
                  'El registro de seguridad (acción realizada e IP) se conserva sin asociarse a tu cuenta.'),
            ],
          ),

          // ── Sección 7: derechos, siempre a la vista ──
          _Seccion(
            numero: 6,
            titulo: 'Derechos del Titular',
            accent: nc.catalogo,
            abierta: true,
            children: [
              const _Parrafo(
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
                _Derecho(icon: icon, derecho: derecho, desc: desc),
              const SizedBox(height: 6),
              const _Parrafo(
                  'El ejercicio de estos derechos no tiene ningún costo. Plazos de '
                  'respuesta: 10 días hábiles para consultas y 15 días hábiles para '
                  'reclamaciones.',
                  pequeno: true),
            ],
          ),

          // ── Sección 8: canales ──
          _Seccion(
            numero: 7,
            titulo: 'Canales para Ejercer tus Derechos',
            accent: nc.azulA,
            abierta: true,
            children: [
              _Canal(
                icon: Icons.mail_outline,
                accent: nc.azulA,
                titulo: 'Correo electrónico',
                texto:
                    '$_kCorreo\nAsunto: "Solicitud de derechos ARCO — [Tipo]"',
                onTap: () => _escribir(context),
              ),
              _Canal(
                icon: Icons.chat_outlined,
                accent: nc.catalogo,
                titulo: 'Chat de soporte',
                texto:
                    'Disponible en la Plataforma para consultas generales sobre '
                    'tratamiento de datos.',
                onTap: () => context.push('/chatbot'),
              ),
              _Canal(
                icon: Icons.language_outlined,
                accent: nc.oroA,
                titulo: 'Formulario web',
                texto: 'Pie de página de la plataforma web → "Política de '
                    'Privacidad → Ejercer mis derechos".',
              ),
              const SizedBox(height: 6),
              const _Parrafo(
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

          const _Seccion(
            numero: 8,
            titulo: 'Medidas de Seguridad',
            children: [
              _Vineta(
                  'Autenticación con tokens JWT firmados (HS256): el acceso dura 30 minutos y la sesión se renueva hasta por 7 días.'),
              _Vineta(
                  'Contraseñas almacenadas con Argon2 (nunca en texto plano).'),
              _Vineta('Comunicaciones cifradas mediante HTTPS/TLS.'),
              _Vineta(
                  'Control de acceso por roles (artista, comprador, gestor, administrador).'),
              _Vineta(
                  'Protección contra inyección SQL mediante ORM de Django.'),
              _Vineta(
                  'Límite de 5 intentos por minuto para iniciar sesión o registrarse, y de 3 solicitudes por hora para recuperar la contraseña.'),
            ],
          ),
          const _Seccion(
            numero: 9,
            titulo: 'Transferencia a Terceros',
            children: [
              _Vineta(
                  'Pasarela de pagos (Wompi): para procesar transacciones.'),
              _Vineta(
                  'Proveedor de correo: envío de notificaciones transaccionales.'),
              _Vineta(
                  'Infraestructura cloud (Railway): alojamiento con garantías de seguridad.'),
              _Vineta(
                  'Proveedor de IA (Google Gemini): el texto que escribes al asistente y los datos de la obra (título, técnica, materiales) cuando pides una descripción con IA. No se envían tu nombre, correo ni teléfono.'),
              SizedBox(height: 8),
              _Parrafo(
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

/// Sección plegable de la política.
class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.numero,
    required this.titulo,
    required this.children,
    this.accent,
    this.abierta = false,
  });

  final int numero;
  final String titulo;
  final List<Widget> children;
  final NcAccent? accent;
  final bool abierta;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: a == null ? nc.bgCard : Color.alphaBlend(a.tint, nc.bgCard),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: a == null ? nc.border : a.fill.withValues(alpha: 0.45)),
        ),
        clipBehavior: Clip.antiAlias,
        // Material propio: sin él, el fondo de la caja tapaba el efecto de
        // toque del ExpansionTile.
        child: Material(
          type: MaterialType.transparency,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: abierta,
              tilePadding: const EdgeInsets.fromLTRB(14, 4, 10, 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              iconColor: a?.ink ?? nc.textSecondary,
              collapsedIconColor: nc.textMuted,
              leading: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: a?.fill ?? nc.itemFill,
                  shape: BoxShape.circle,
                ),
                child: Text('$numero',
                    style: AppTypography.labelMedium(
                            color: a?.onFill ?? nc.textSecondary)
                        .copyWith(fontWeight: FontWeight.w800)),
              ),
              title: Text(titulo,
                  style: AppTypography.labelSemiBold(
                      color: a?.ink ?? nc.textPrimary)),
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _Parrafo extends StatelessWidget {
  const _Parrafo(this.text, {this.pequeno = false});

  final String text;
  final bool pequeno;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Text(text,
        style: pequeno
            ? AppTypography.bodySmall(color: nc.textSecondary)
            : AppTypography.bodyMedium(color: nc.textSecondary));
  }
}

class _Subtitulo extends StatelessWidget {
  const _Subtitulo(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child:
          Text(text, style: AppTypography.labelSemiBold(color: nc.textPrimary)),
    );
  }
}

class _Vineta extends StatelessWidget {
  const _Vineta(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 10),
            width: 5,
            height: 5,
            decoration:
                BoxDecoration(color: nc.textMuted, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(text,
                style: AppTypography.bodyMedium(color: nc.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySmall(color: nc.textMuted)),
          const SizedBox(height: 2),
          SelectableText(value,
              style: AppTypography.bodyMedium(color: nc.textPrimary)),
        ],
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.icon, required this.accent, required this.text});

  final IconData icon;
  final NcAccent accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NcAccentIcon(icon: icon, accent: accent, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(text,
                  style: AppTypography.bodyMedium(color: nc.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Derecho extends StatelessWidget {
  const _Derecho(
      {required this.icon, required this.derecho, required this.desc});

  final IconData icon;
  final String derecho;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = nc.catalogo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: a.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: '$derecho. ',
                    style: AppTypography.labelSemiBold(color: nc.textPrimary)),
                TextSpan(
                    text: desc,
                    style: AppTypography.bodyMedium(color: nc.textSecondary)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Canal extends StatelessWidget {
  const _Canal({
    required this.icon,
    required this.accent,
    required this.titulo,
    required this.texto,
    this.onTap,
  });

  final IconData icon;
  final NcAccent accent;
  final String titulo;
  final String texto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fila = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NcAccentIcon(icon: icon, accent: accent, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: AppTypography.labelSemiBold(color: nc.textPrimary)),
                const SizedBox(height: 2),
                Text(texto,
                    style: AppTypography.bodySmall(color: nc.textSecondary)),
              ],
            ),
          ),
          if (onTap != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(Icons.chevron_right_rounded, color: nc.textMuted),
            ),
        ],
      ),
    );
    if (onTap == null) return fila;
    return Semantics(
      button: true,
      label: titulo,
      child: NcPressable(onTap: onTap, pressedScale: 0.98, child: fila),
    );
  }
}
