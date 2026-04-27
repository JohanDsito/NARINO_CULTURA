import 'artwork_model.dart';

enum ArtworkStatus { initial, loading, loaded, error }

class ArtworkState {
  final ArtworkStatus status;
  final List<ArtworkModel> artworks;
  final String? errorMessage;
  final int totalResultados;

  final String busqueda;
  final String? categoriaFiltro;
  final String? tecnicaFiltro;
  final double? precioMinFiltro;
  final double? precioMaxFiltro;
  final String ordenarPor;
  final bool soloFavoritos;

  const ArtworkState({
    this.status = ArtworkStatus.initial,
    this.artworks = const [],
    this.errorMessage,
    this.totalResultados = 0,
    this.busqueda = '',
    this.categoriaFiltro,
    this.tecnicaFiltro,
    this.precioMinFiltro,
    this.precioMaxFiltro,
    this.ordenarPor = 'fecha',
    this.soloFavoritos = false,
  });

  ArtworkState copyWith({
    ArtworkStatus? status,
    List<ArtworkModel>? artworks,
    String? errorMessage,
    int? totalResultados,
    String? busqueda,
    String? categoriaFiltro,
    String? tecnicaFiltro,
    double? precioMinFiltro,
    double? precioMaxFiltro,
    String? ordenarPor,
    bool? soloFavoritos,
    bool clearError = false,
    bool clearCategoriaFiltro = false,
    bool clearTecnicaFiltro = false,
  }) =>
      ArtworkState(
        status: status ?? this.status,
        artworks: artworks ?? this.artworks,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        totalResultados: totalResultados ?? this.totalResultados,
        busqueda: busqueda ?? this.busqueda,
        categoriaFiltro: clearCategoriaFiltro
            ? null
            : (categoriaFiltro ?? this.categoriaFiltro),
        tecnicaFiltro:
            clearTecnicaFiltro ? null : (tecnicaFiltro ?? this.tecnicaFiltro),
        precioMinFiltro: precioMinFiltro ?? this.precioMinFiltro,
        precioMaxFiltro: precioMaxFiltro ?? this.precioMaxFiltro,
        ordenarPor: ordenarPor ?? this.ordenarPor,
        soloFavoritos: soloFavoritos ?? this.soloFavoritos,
      );

  bool get isLoading => status == ArtworkStatus.loading;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  bool get hayFiltrosActivos =>
      busqueda.isNotEmpty ||
      categoriaFiltro != null ||
      tecnicaFiltro != null ||
      precioMinFiltro != null ||
      precioMaxFiltro != null ||
      soloFavoritos;
}
