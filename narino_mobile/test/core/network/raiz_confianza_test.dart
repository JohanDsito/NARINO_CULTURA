import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/network/raiz_confianza.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = Uint8List.fromList(utf8.encode('PEM'));
  Future<Uint8List> cargar() async => bytes;

  test('el asset es exactamente ISRG Root X1 (huella SHA-256 oficial)', () {
    final pem = File(rutaIsrgRootX1).readAsStringSync();
    expect(RegExp('BEGIN CERTIFICATE').allMatches(pem).length, 1);
    expect(RegExp(r'-----BEGIN ').allMatches(pem).length, 1,
        reason: 'sin claves ni otros bloques PEM');
    final der = base64.decode(pem
        .replaceAll(RegExp(r'-----[A-Z ]+-----'), '')
        .replaceAll(RegExp(r'\s'), ''));
    // Huella publicada por Let's Encrypt en letsencrypt.org/certificates.
    expect(
      sha256.convert(der).toString(),
      '96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6',
    );
  });

  test('en Android agrega los bytes al contexto', () async {
    List<int>? recibido;
    var llamadas = 0;
    await RaizConfianza.instalar(
        agregar: (b) {
          llamadas++;
          recibido = b;
        },
        esAndroid: true,
        cargarBytes: cargar);
    expect(llamadas, 1);
    expect(recibido, bytes);
  });

  test('fuera de Android no toca el contexto', () async {
    var llamadas = 0;
    await RaizConfianza.instalar(
        agregar: (_) => llamadas++, esAndroid: false, cargarBytes: cargar);
    expect(llamadas, 0);
  });

  test('ignora CERT_ALREADY_IN_HASH_TABLE', () async {
    var llamadas = 0;
    await RaizConfianza.instalar(
        agregar: (_) {
          llamadas++;
          throw const TlsException('Failure trusting builtin roots',
              OSError('CERT_ALREADY_IN_HASH_TABLE', 0));
        },
        esAndroid: true,
        cargarBytes: cargar);
    expect(llamadas, 1);
  });

  test('propaga otras TlsException', () async {
    expect(
      RaizConfianza.instalar(
          agregar: (_) => throw const TlsException('certificado inválido'),
          esAndroid: true,
          cargarBytes: cargar),
      throwsA(isA<TlsException>()),
    );
  });

  test('el PEM real se acepta en un contexto sin raíces del sistema', () async {
    final ctx = SecurityContext(withTrustedRoots: false);
    await RaizConfianza.instalar(
      agregar: ctx.setTrustedCertificatesBytes,
      esAndroid: true,
      cargarBytes: () async => File(rutaIsrgRootX1).readAsBytesSync(),
    );
  });
}
