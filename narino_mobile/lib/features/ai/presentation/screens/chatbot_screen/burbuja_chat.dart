import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import 'avatar_asistente.dart';
import 'mensaje_chat.dart';
import 'puntos_escribiendo.dart';
import 'texto_asistente.dart';

class BurbujaChat extends StatelessWidget {
  const BurbujaChat({
    super.key,
    required this.m,
    required this.conAvatar,
    this.onReintentar,
  });

  final MensajeChat m;
  final bool conAvatar;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final ancho = MediaQuery.sizeOf(context).width * 0.78;

    if (!m.deBot) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 48),
          constraints: BoxConstraints(maxWidth: ancho),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: nc.azulA.fill,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: SelectableText(m.texto,
              style: AppTypography.bodyMedium(color: nc.azulA.onFill)),
        ),
      );
    }

    final error = m.estado == EstadoMensaje.error;
    final contenido = switch (m.estado) {
      EstadoMensaje.escribiendo => const PuntosEscribiendo(),
      EstadoMensaje.error => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 18, color: nc.tomateA.ink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(m.texto,
                      style: AppTypography.bodyMedium(color: nc.textPrimary)),
                ),
              ],
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: onReintentar,
                style: TextButton.styleFrom(
                  foregroundColor: nc.tomateA.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      EstadoMensaje.listo => TextoAsistente(m.texto),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 30,
            child: conAvatar ? const AvatarAsistente(size: 28) : null,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: GestureDetector(
              onLongPress: m.estado == EstadoMensaje.listo
                  ? () {
                      Clipboard.setData(ClipboardData(text: m.texto));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Respuesta copiada')));
                    }
                  : null,
              child: Container(
                constraints: BoxConstraints(maxWidth: ancho),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: error
                      ? Color.alphaBlend(nc.tomateA.tint, nc.bgCard)
                      : nc.bgCard,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                      color: error
                          ? nc.tomateA.fill.withValues(alpha: 0.4)
                          : nc.border),
                ),
                child: contenido,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
