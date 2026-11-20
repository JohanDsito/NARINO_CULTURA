/// "3:45" → 225 segundos. También acepta solo segundos ("225").
/// `null` si está vacío o no es válido.
int? segundosDeDuracion(String texto) {
  final v = texto.trim();
  if (v.isEmpty) return null;
  if (v.contains(':')) {
    final p = v.split(':');
    final m = int.tryParse(p[0]);
    final s = int.tryParse(p.length > 1 ? p[1] : '0');
    if (m == null || s == null || s > 59) return null;
    return m * 60 + s;
  }
  return int.tryParse(v);
}
