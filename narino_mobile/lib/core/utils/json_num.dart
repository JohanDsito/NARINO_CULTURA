/// Lectura tolerante de números desde JSON.
///
/// Django serializa los `DecimalField` (coordenadas, precios) como texto
/// (p. ej. `"1.213611"`), así que un `as num?` directo lanza
/// `type 'String' is not a subtype of type 'num'`.
///
/// Acepta `num`, `String` numérica o `null`; cualquier otra cosa da `null`.
double? parseJsonDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

/// Igual que [parseJsonDouble] pero con valor por defecto cuando no se puede leer.
double parseJsonDoubleOr(Object? value, double fallback) =>
    parseJsonDouble(value) ?? fallback;
