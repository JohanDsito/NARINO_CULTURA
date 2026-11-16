import 'artwork_model.dart';

enum ArtworkStatus { initial, loading, loaded, error }

class ArtworkState {
  final ArtworkStatus status;
  final List<ArtworkModel> artworks;
  final String? errorMessage;
  final int totalResultados;

  /// Última página pedida al backend (MO-LOAD-01: scroll infinito).
  final int page;

  /// Obras recibidas del servidor (antes de filtrar favoritos en el teléfono):
  /// sirve para saber si quedan páginas.
  final int cargadas;
  final bool isLoadingMore;

  /// Falló la página siguiente; las ya cargadas siguen en pantalla.
  final String? loadMoreError;

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
    this.page = 1,
    this.cargadas = 0,
    this.isLoadingMore = false,
    this.loadMoreError,
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
    int? page,
    int? cargadas,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
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
    bool clearPrecio = false,
  }) =>
      ArtworkState(
        status: status ?? this.status,
        artworks: artworks ?? this.artworks,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        totalResultados: totalResultados ?? this.totalResultados,
        page: page ?? this.page,
        cargadas: cargadas ?? this.cargadas,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreError: clearLoadMoreError
            ? null
            : (loadMoreError ?? this.loadMoreError),
        busqueda: busqueda ?? this.busqueda,
        categoriaFiltro: clearCategoriaFiltro
            ? null
            : (categoriaFiltro ?? this.categoriaFiltro),
        tecnicaFiltro:
            clearTecnicaFiltro ? null : (tecnicaFiltro ?? this.tecnicaFiltro),
        precioMinFiltro:
            clearPrecio ? precioMinFiltro : (precioMinFiltro ?? this.precioMinFiltro),
        precioMaxFiltro:
            clearPrecio ? precioMaxFiltro : (precioMaxFiltro ?? this.precioMaxFiltro),
        ordenarPor: ordenarPor ?? this.ordenarPor,
        soloFavoritos: soloFavoritos ?? this.soloFavoritos,
      );

  bool get isLoading => status == ArtworkStatus.loading;

  /// Quedan obras en el servidor por traer.
  bool get hasMore => cargadas < totalResultados;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  /// Filtros del panel (sin contar la búsqueda): categoría, técnica, precio
  /// y orden distinto al predeterminado.
  int get filtrosPanelActivos => [
        categoriaFiltro != null,
        tecnicaFiltro != null,
        precioMinFiltro != null || precioMaxFiltro != null,
        ordenarPor != 'fecha',
      ].where((b) => b).length;

  bool get hayFiltrosActivos =>
      busqueda.isNotEmpty ||
      categoriaFiltro != null ||
      tecnicaFiltro != null ||
      precioMinFiltro != null ||
      precioMaxFiltro != null ||
      soloFavoritos;
}
