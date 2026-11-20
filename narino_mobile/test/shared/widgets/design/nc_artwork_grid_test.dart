import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/shared/widgets/design/nc_artwork_grid.dart';

/// Columnas que da la rejilla de obras con [width] dp disponibles.
int _columns(double width) {
  final layout = ncArtworkGridDelegate.getLayout(SliverConstraints(
    axisDirection: AxisDirection.down,
    growthDirection: GrowthDirection.forward,
    userScrollDirection: ScrollDirection.idle,
    scrollOffset: 0,
    precedingScrollExtent: 0,
    overlap: 0,
    remainingPaintExtent: 800,
    crossAxisExtent: width,
    crossAxisDirection: AxisDirection.right,
    viewportMainAxisExtent: 800,
    remainingCacheExtent: 800,
    cacheOrigin: 0,
  )) as SliverGridRegularTileLayout;
  return layout.crossAxisCount;
}

void main() {
  // MO-COMP-03: 2 columnas en teléfono y más en tablet (antes siempre 2).
  // Los anchos ya descuentan el margen lateral de 16 dp de cada lado.
  test('teléfonos pequeños y comunes: 2 columnas', () {
    expect(_columns(320 - 32), 2);
    expect(_columns(360 - 32), 2);
    expect(_columns(412 - 32), 2);
  });

  test('tablet vertical: 3 columnas; horizontal: 4 o más', () {
    expect(_columns(768 - 32), 3);
    expect(_columns(1024 - 32), greaterThanOrEqualTo(4));
  });
}
