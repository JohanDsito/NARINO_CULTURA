import 'package:flutter/material.dart';

/// Un color de acento del carnaval con sus cuatro usos.
///
/// - [fill]: relleno neón (botones, chips activos, insignias).
/// - [onFill]: texto/ícono sobre [fill] (negro en los neón cálidos, como las
///   letras de las carrozas; blanco sobre magenta y sobre el azul claro).
/// - [ink]: el color usado como TEXTO sobre el fondo. En modo claro es una
///   versión más oscura para cumplir contraste ≥ 4.5:1.
/// - [tint]: fondo suave del color (16 % en oscuro, 10 % en claro).
@immutable
class NcAccent {
  const NcAccent({
    required this.fill,
    required this.onFill,
    required this.ink,
    required this.tint,
  });

  final Color fill;
  final Color onFill;
  final Color ink;
  final Color tint;
}
