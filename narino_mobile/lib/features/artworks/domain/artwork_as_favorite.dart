import '../../marketplace/domain/favorite_model.dart';
import 'artwork_model.dart';

/// Datos de una obra con la forma de un favorito, para mostrarla en
/// Favoritos apenas se marca, sin volver a pedir toda la lista.
extension ArtworkAsFavorite on ArtworkModel {
  FavoriteModel toFavorite() => FavoriteModel(
        id: '',
        obraId: id,
        obraTitulo: titulo,
        artistaNombre: artistaNombre,
        estado: estado,
        precio: precio,
        imagenUrl: imagenes.isEmpty ? null : imagenes.first,
      );
}
