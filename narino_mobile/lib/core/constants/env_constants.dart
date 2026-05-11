class EnvConstants {
  EnvConstants._();

  static const String devBaseUrl = 'http://10.0.2.2:8000/api/v1';
  // TODO: reemplazar con URL de Render en producción
  static const String prodBaseUrl = 'https://example.onrender.com/api/v1';

  static String get apiBaseUrl =>
      const bool.fromEnvironment('dart.vm.product') ? prodBaseUrl : devBaseUrl;
}

