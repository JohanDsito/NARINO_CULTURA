import 'package:flutter/rendering.dart';

/// Rejilla de tarjetas de obra (catálogo, tienda, favoritos, mis obras, perfil).
///
/// Calcula las columnas según el ancho disponible: 2 en teléfono, 3 en tablet
/// vertical y 4 en horizontal. Con un número fijo de columnas las tarjetas se
/// estiraban en tablet (MO-COMP-03).
const ncArtworkGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 240,
  crossAxisSpacing: 12,
  mainAxisSpacing: 14,
  childAspectRatio: 0.64,
);
