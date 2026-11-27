/// Resultado de evaluar si una URL de backend es apta para correr pruebas de integración.
enum DecisionEntorno {
  /// URL permitida (servidor local o de pruebas).
  permitir,

  /// URL de producción o vacía: las pruebas deben abortar.
  abortar,
}
