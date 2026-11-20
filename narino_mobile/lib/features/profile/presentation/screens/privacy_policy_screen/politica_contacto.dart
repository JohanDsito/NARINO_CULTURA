import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Correo para ejercer los derechos sobre los datos personales.
const kCorreoPrivacidad = 'privacidad@nariniocultura.edu.co';

/// Abre un correo a [kCorreoPrivacidad] con la plantilla ARCO.
///
/// canLaunchUrl('mailto:') da false en Android 11+ sin <queries>: se intenta
/// abrir directo y, si no hay app de correo, se copia la dirección.
Future<void> escribirAPrivacidad(BuildContext context) async {
  final uri = Uri(
    scheme: 'mailto',
    path: kCorreoPrivacidad,
    queryParameters: {
      'subject': 'Solicitud de derechos ARCO — [Tipo de solicitud]',
      'body': 'Nombre completo: \nCorreo registrado: \nTipo de solicitud: \n'
          'Descripción: ',
    },
  );
  var abierto = false;
  try {
    abierto = await launchUrl(uri);
  } catch (_) {}
  if (abierto || !context.mounted) return;
  await Clipboard.setData(const ClipboardData(text: kCorreoPrivacidad));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('No encontramos una app de correo. Copiamos la '
          'dirección para que la pegues.')));
}
