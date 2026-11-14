import 'package:flutter/material.dart';

/// Funciones cuyo endpoint aún no existe en el backend (ver MAPA_TRABAJO #7, #8).
const kFuncionesProximas = {'portafolio', 'correo', 'sesiones'};

/// Avisa que una función todavía no está disponible.
void avisarProximamente(BuildContext context, String que) =>
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          content: Text('$que estará disponible muy pronto. Estamos '
              'terminando esta función en el servidor.')));
