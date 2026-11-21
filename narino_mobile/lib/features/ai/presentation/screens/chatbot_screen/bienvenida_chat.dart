import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import 'avatar_asistente.dart';

class BienvenidaChat extends StatelessWidget {
  const BienvenidaChat({super.key, required this.onSugerencia});

  final ValueChanged<String> onSugerencia;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final sugerencias = [
      (
        Icons.celebration_outlined,
        nc.tomateA,
        'El Carnaval',
        'Cuéntame la historia del Carnaval de Negros y Blancos.'
      ),
      (
        Icons.music_note_rounded,
        nc.azulA,
        'Música',
        'Recomiéndame bandas de música andina de Nariño.'
      ),
      (
        Icons.content_cut_rounded,
        nc.naranjaA,
        'Artesanía',
        '¿Qué es el barniz de Pasto y quién lo trabaja?'
      ),
      (
        Icons.event_rounded,
        nc.catalogo,
        'Eventos',
        '¿Qué eventos culturales hay pronto en Nariño?'
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      children: [
        const Center(child: AvatarAsistente(size: 84)),
        const SizedBox(height: 18),
        Text('¡Hola! Soy tu guía cultural',
            textAlign: TextAlign.center,
            style: AppTypography.displayBold(color: nc.textPrimary)
                .copyWith(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          'Pregúntame por artistas, obras, música y eventos de Nariño. '
          'Escribe como le hablarías a una amiga.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium(color: nc.textSecondary),
        ),
        const SizedBox(height: 24),
        // Dos filas de tarjetas que crecen con el texto (con letra grande la
        // cuadrícula de alto fijo se desbordaba).
        for (var fila = 0; fila < sugerencias.length; fila += 2) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (icon, accent, titulo, pregunta)
                    in sugerencias.skip(fila).take(2)) ...[
                  if (sugerencias.indexOf((icon, accent, titulo, pregunta)) !=
                      fila)
                    const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Preguntar: $pregunta',
                      onTap: () => onSugerencia(pregunta),
                      excludeSemantics: true,
                      child: NcPressable(
                        onTap: () => onSugerencia(pregunta),
                        pressedScale: 0.96,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(accent.tint, nc.bgCard),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: accent.fill.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              NcAccentIcon(
                                  icon: icon, accent: accent, size: 34),
                              const SizedBox(height: 14),
                              Text(titulo,
                                  style: AppTypography.labelSemiBold(
                                      color: accent.ink)),
                              const SizedBox(height: 2),
                              Text(pregunta,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall(
                                          color: nc.textSecondary)
                                      .copyWith(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        Text(
          'Las respuestas las genera una IA y pueden tener errores.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall(color: nc.textMuted),
        ),
      ],
    );
  }
}
