import 'package:flutter/material.dart';

import '../../../core/theme/nc_theme.dart';

/// Pregunta "¿Seguro?" y devuelve `true` si se confirma.
///
/// Con [peligro] el botón de confirmar va en tomate (eliminar, salir…).
Future<bool> confirmarAccion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String confirmar,
  String cancelar = 'Cancelar',
  bool peligro = false,
}) async {
  final nc = context.nc;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelar),
        ),
        peligro
            ? FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: nc.tomateA.fill,
                  foregroundColor: nc.tomateA.onFill,
                ),
                child: Text(confirmar),
              )
            : TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmar),
              ),
      ],
    ),
  );
  return ok == true;
}
