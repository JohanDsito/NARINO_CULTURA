import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ruta del certificado raíz ISRG Root X1 (público, de Let's Encrypt).
const String rutaIsrgRootX1 = 'assets/certs/isrg_root_x1.pem';

/// Añade ISRG Root X1 a la confianza TLS de la app.
///
/// Android anterior a 7.1.1 no trae esa raíz y la cadena del backend
/// (Let's Encrypt) termina en ella. No se desactiva ninguna validación:
/// solo se agrega una raíz pública más a las de confianza.
/// Solo actúa en Android; en otras plataformas el almacén del sistema basta.
abstract final class RaizConfianza {
  /// Instala la raíz con [agregar] (por defecto
  /// `SecurityContext.defaultContext.setTrustedCertificatesBytes`).
  ///
  /// Si el sistema ya la trae, Android lanza `CERT_ALREADY_IN_HASH_TABLE`:
  /// esa excepción concreta se ignora; cualquier otro error se propaga.
  /// [agregar], [esAndroid] y [cargarBytes] son inyectables para pruebas.
  static Future<void> instalar({
    void Function(List<int> bytes)? agregar,
    bool? esAndroid,
    Future<Uint8List> Function()? cargarBytes,
  }) async {
    final android = esAndroid ?? (!kIsWeb && Platform.isAndroid);
    if (!android) return;
    final bytes = await (cargarBytes ?? _cargarAsset)();
    final destino = agregar ??
        (List<int> b) =>
            SecurityContext.defaultContext.setTrustedCertificatesBytes(b);
    try {
      destino(bytes);
    } on TlsException catch (e) {
      if (!_esDuplicado(e)) rethrow;
    }
  }

  static bool _esDuplicado(TlsException e) =>
      '${e.message} ${e.osError?.message ?? ''}'
          .contains('CERT_ALREADY_IN_HASH_TABLE');

  static Future<Uint8List> _cargarAsset() async {
    final datos = await rootBundle.load(rutaIsrgRootX1);
    return datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes);
  }
}
