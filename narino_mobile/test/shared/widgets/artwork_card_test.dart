import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/shared/widgets/artwork_card.dart';

import '../../support/test_helpers.dart';

Widget _wrapCard(Widget card) {
  return wrap(Scaffold(
    body: SizedBox(width: 180, height: 260, child: card),
  ));
}

void main() {
  setUpAll(ensureApiClientInitialized);

  // MO-WT-05
  testWidgets('ArtworkCard renderiza el título y el nombre del artista',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapCard(ArtworkCard(
      artwork: testArtwork(titulo: 'Barniz de Pasto', artistaNombre: 'Ana Díaz'),
    )));

    expect(find.text('Barniz de Pasto'), findsOneWidget);
    expect(find.text('Ana Díaz'), findsOneWidget);
  });

  // MO-WT-06
  testWidgets('ArtworkCard sin imágenes muestra el ícono de paleta',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapCard(ArtworkCard(
      artwork: testArtwork(imagenes: const []),
    )));

    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
  });

  // MO-WT-07
  testWidgets('ArtworkCard formatea el precio con separadores de miles en COP',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapCard(ArtworkCard(
      artwork: testArtwork(precio: 1500000),
    )));

    expect(find.text(r'$1.500.000 COP'), findsOneWidget);
  });

  // MO-WT-08
  testWidgets('ArtworkCard muestra el badge "Vendida" cuando estado es vendida',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapCard(ArtworkCard(
      artwork: testArtwork(estado: 'vendida'),
    )));

    expect(find.text('Vendida'), findsOneWidget);
  });
}
