import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

/// Texto del bot con el markdown sencillo que usa Gemini: **negrita**,
/// viñetas (`*`, `-`, `•`) y títulos (`#`).
class TextoAsistente extends StatelessWidget {
  const TextoAsistente(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final base = AppTypography.bodyMedium(color: nc.textPrimary);
    final negrita = base.copyWith(fontWeight: FontWeight.w700);

    List<TextSpan> enLinea(String s, {bool titulo = false}) {
      final spans = <TextSpan>[];
      final partes = s.split('**');
      for (var i = 0; i < partes.length; i++) {
        if (partes[i].isEmpty) continue;
        spans.add(TextSpan(
            text: partes[i], style: (i.isOdd || titulo) ? negrita : base));
      }
      return spans;
    }

    final filas = <Widget>[];
    for (final raw in texto.trim().split('\n')) {
      final l = raw.trimRight();
      if (l.trim().isEmpty) {
        if (filas.isNotEmpty) filas.add(const SizedBox(height: 6));
        continue;
      }
      final vineta = RegExp(r'^\s*([*\-•]|\d+\.)\s+').firstMatch(l);
      final titulo = RegExp(r'^\s*#{1,4}\s+').firstMatch(l);
      if (vineta != null) {
        final marca = vineta.group(1)!;
        filas.add(Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 18,
                child: Text(RegExp(r'\d').hasMatch(marca) ? marca : '•',
                    style: base.copyWith(color: nc.azul)),
              ),
              Expanded(
                  child: Text.rich(
                      TextSpan(children: enLinea(l.substring(vineta.end))))),
            ],
          ),
        ));
      } else if (titulo != null) {
        filas.add(Text.rich(TextSpan(
            children: enLinea(l.substring(titulo.end), titulo: true))));
      } else {
        filas.add(Text.rich(TextSpan(children: enLinea(l))));
      }
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: filas);
  }
}
