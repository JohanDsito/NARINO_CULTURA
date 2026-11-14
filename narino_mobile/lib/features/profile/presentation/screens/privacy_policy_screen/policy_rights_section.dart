import 'package:flutter/material.dart';

import '../../../../../core/theme/nc_theme.dart';
import 'policy_paragraph.dart';
import 'policy_right_row.dart';
import 'policy_section.dart';

/// Sección 6: derechos del titular (siempre abierta).
class PolicyRightsSection extends StatelessWidget {
  const PolicyRightsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return PolicySection(
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
    );
  }
}
