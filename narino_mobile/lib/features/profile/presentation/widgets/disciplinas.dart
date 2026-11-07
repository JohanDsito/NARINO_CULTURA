import 'package:flutter/material.dart';

import '../../../../core/theme/nc_theme.dart';

/// Disciplina artística que se muestra en la app.
///
/// [value] es lo que se guarda en el backend (`discipline`, texto libre) y
/// coincide con lo que guarda la web (Artesano, Fotógrafo, Escultor, Pintor,
/// Música). [label] es el nombre neutro que se ve.
class Disciplina {
  const Disciplina(
      this.label, this.value, this.icon, this.description, this.accent);

  final String label;
  final String value;
  final IconData icon;
  final String description;
  final NcAccent Function(NcColors) accent;
}

final kDisciplinas = <Disciplina>[
  Disciplina('Artesanía', 'Artesano', Icons.content_cut_rounded,
      'Barniz de Pasto, tamo, tejidos y técnicas tradicionales.',
      (nc) => nc.naranjaA),
  Disciplina('Fotografía', 'Fotógrafo', Icons.camera_alt_outlined,
      'El Carnaval, los paisajes y la gente del territorio.', (nc) => nc.azulA),
  Disciplina('Escultura', 'Escultor', Icons.architecture_rounded,
      'Formas en madera, piedra, metal y otros materiales.', (nc) => nc.oroA),
  Disciplina('Pintura', 'Pintor', Icons.brush_outlined,
      'Lienzo, mural, acuarela y otras superficies.', (nc) => nc.magentaA),
  Disciplina('Música', 'Música', Icons.music_note_rounded,
      'Composición, interpretación y producción musical.', (nc) => nc.tomateA),
];

/// Minúsculas y sin tildes, para comparar textos libres del backend.
String normalizarDisciplina(String? s) {
  const con = 'áéíóúüñ';
  const sin = 'aeiouun';
  final b = StringBuffer();
  for (final ch in (s ?? '').trim().toLowerCase().split('')) {
    final i = con.indexOf(ch);
    b.write(i >= 0 ? sin[i] : ch);
  }
  return b.toString();
}

/// Sinónimos que llegan del backend (lo escriben la app, la web y el admin).
const _kSinonimos = <String, String>{
  'artesano': 'Artesano',
  'artesana': 'Artesano',
  'artesania': 'Artesano',
  'fotografo': 'Fotógrafo',
  'fotografa': 'Fotógrafo',
  'fotografia': 'Fotógrafo',
  'escultor': 'Escultor',
  'escultora': 'Escultor',
  'escultura': 'Escultor',
  'pintor': 'Pintor',
  'pintora': 'Pintor',
  'pintura': 'Pintor',
  'musica': 'Música',
  'musico': 'Música',
  'musicos': 'Música',
};

/// La disciplina conocida que corresponde a [valor], o `null` si es otra.
Disciplina? disciplinaDe(String? valor) {
  final canon = _kSinonimos[normalizarDisciplina(valor)];
  if (canon == null) return null;
  return kDisciplinas.firstWhere((d) => d.value == canon);
}

/// `true` si [valor] es música en cualquiera de sus formas
/// ("Música", "Musica", "Músico"…).
bool esDisciplinaMusical(String? valor) => disciplinaDe(valor)?.value == 'Música';
