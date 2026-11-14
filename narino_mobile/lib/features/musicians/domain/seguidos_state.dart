// ─── A quién sigo ─────────────────────────────────────────────────────────────

/// Estado de "seguir" como única fuente de verdad para lista y detalle.
/// [inicial] es lo que dijo el servidor al cargar; [actual] incluye los
/// cambios optimistas. La diferencia sirve para ajustar el contador.
class SeguidosState {
  const SeguidosState({this.inicial = const {}, this.actual = const {}});
  final Set<String> inicial;
  final Set<String> actual;

  bool sigue(String slug) => actual.contains(slug);

  /// +1 / −1 / 0 respecto al conteo que trajo el backend.
  int delta(String slug, {required bool servidorDiceQueSigue}) {
    final antes = servidorDiceQueSigue || inicial.contains(slug);
    final ahora = actual.contains(slug);
    return (ahora ? 1 : 0) - (antes ? 1 : 0);
  }
}
