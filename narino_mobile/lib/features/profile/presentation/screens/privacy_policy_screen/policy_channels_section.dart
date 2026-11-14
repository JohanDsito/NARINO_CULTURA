import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import 'policy_contact_channel.dart';
import 'policy_paragraph.dart';
import 'policy_section.dart';
import 'politica_contacto.dart';

/// Sección 7: canales para ejercer los derechos (siempre abierta).
class PolicyChannelsSection extends StatelessWidget {
  const PolicyChannelsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return PolicySection(
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
              '$kCorreoPrivacidad\nAsunto: "Solicitud de derechos ARCO — [Tipo]"',
          onTap: () => escribirAPrivacidad(context),
        ),
        PolicyContactChannel(
          icon: Icons.chat_outlined,
          accent: nc.catalogo,
          titulo: 'Chat de soporte',
          texto: 'Disponible en la Plataforma para consultas generales sobre '
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
          onPressed: () => escribirAPrivacidad(context),
        ),
      ],
    );
  }
}
