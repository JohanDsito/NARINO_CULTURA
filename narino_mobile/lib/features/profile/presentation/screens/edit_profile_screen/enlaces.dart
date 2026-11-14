/// Convierte lo que escribe la persona en una URL que acepte el backend
/// (`URLField`): agrega `https://` y entiende `@usuario` en Instagram/TikTok.
String normalizarEnlace(String red, String texto) {
  var v = texto.trim();
  if (v.isEmpty) return '';
  if (v.startsWith('@')) {
    final user = v.substring(1);
    switch (red) {
      case 'instagram':
        return 'https://instagram.com/$user';
      case 'tiktok':
        return 'https://www.tiktok.com/@$user';
      case 'facebook':
        return 'https://facebook.com/$user';
    }
  }
  if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(v)) {
    v = 'https://$v';
  }
  return v;
}

/// `true` si [url] está vacía (se puede quitar la red) o parece una URL.
bool enlaceValido(String url) {
  if (url.isEmpty) return true;
  final u = Uri.tryParse(url);
  return u != null && u.host.contains('.') && !url.contains(' ');
}
