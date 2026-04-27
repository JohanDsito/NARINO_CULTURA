import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/artwork_model.dart';
import '../../domain/artwork_state.dart';
import '../providers/artwork_provider.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(artworkProvider.notifier).loadCatalog());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(artworkProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(
          'Catálogo',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        backgroundColor: AppColors.obsidiana,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push('/artworks/publish'),
            icon: const Icon(Icons.add, color: AppColors.oroClaro),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/artworks/publish'),
        backgroundColor: AppColors.oroAndino,
        foregroundColor: AppColors.obsidiana,
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(artworkProvider.notifier).loadCatalog(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _buildSearch(state),
            const SizedBox(height: 12),
            _buildFilters(state),
            const SizedBox(height: 12),
            _buildSummary(state),
            const SizedBox(height: 12),
            if (state.hasError)
              _ErrorCard(
                message: state.errorMessage!,
                onRetry: () => ref.read(artworkProvider.notifier).loadCatalog(),
              )
            else if (state.isLoading && state.artworks.isEmpty)
              const _LoadingList()
            else if (state.artworks.isEmpty)
              const _EmptyState()
            else
              ...state.artworks.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ArtworkCard(
                    artwork: a,
                    onTap: () => context.push('/artworks/${a.id}'),
                    onFavorite: () =>
                        ref.read(artworkProvider.notifier).toggleFavorite(a.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(ArtworkState state) {
    if (_searchCtrl.text != state.busqueda) {
      _searchCtrl.text = state.busqueda;
      _searchCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchCtrl.text.length),
      );
    }

    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => ref.read(artworkProvider.notifier).setBusqueda(v),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por título, artista, técnica...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: state.busqueda.isEmpty
            ? null
            : IconButton(
                onPressed: () =>
                    ref.read(artworkProvider.notifier).setBusqueda(''),
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: AppColors.bgCardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.tierraClara, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilters(ArtworkState state) {
    final notifier = ref.read(artworkProvider.notifier);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: state.categoriaFiltro == null
              ? 'Categoría'
              : 'Categoría: ${state.categoriaFiltro}',
          selected: state.categoriaFiltro != null,
          onTap: () => _pickCategoria(
            selected: state.categoriaFiltro,
            onSelected: notifier.setCategoria,
          ),
        ),
        _FilterChip(
          label: state.tecnicaFiltro == null
              ? 'Técnica'
              : 'Técnica: ${state.tecnicaFiltro}',
          selected: state.tecnicaFiltro != null,
          onTap: () => _pickTecnica(
            selected: state.tecnicaFiltro,
            onSelected: notifier.setTecnica,
          ),
        ),
        _FilterChip(
          label: _priceLabel(state),
          selected:
              state.precioMinFiltro != null || state.precioMaxFiltro != null,
          onTap: () => _pickPrecio(
            min: state.precioMinFiltro,
            max: state.precioMaxFiltro,
            onSelected: notifier.setRangoPrecio,
          ),
        ),
        _FilterChip(
          label: _ordenLabel(state.ordenarPor),
          selected: true,
          onTap: () => _pickOrden(
            selected: state.ordenarPor,
            onSelected: notifier.setOrden,
          ),
        ),
        FilterChip(
          selected: state.soloFavoritos,
          label: const Text('Favoritos'),
          onSelected: (v) => notifier.setSoloFavoritos(v),
          selectedColor: AppColors.oroPalido,
          checkmarkColor: AppColors.obsidiana,
          side: const BorderSide(color: AppColors.borderLight),
          backgroundColor: AppColors.bgCardLight,
          labelStyle:
              AppTypography.labelMedium(color: AppColors.textPrimaryLight),
        ),
        if (state.hayFiltrosActivos)
          TextButton(
            onPressed: () => notifier.limpiarFiltros(),
            child: Text(
              'Limpiar',
              style: AppTypography.labelSemiBold(color: AppColors.indigoNoche),
            ),
          ),
      ],
    );
  }

  Widget _buildSummary(ArtworkState state) {
    final total = state.totalResultados;
    final label = total == 1 ? '1 resultado' : '$total resultados';
    return Row(
      children: [
        Text(
          label,
          style:
              AppTypography.labelSemiBold(color: AppColors.textSecondaryLight),
        ),
        if (state.isLoading) ...[
          const SizedBox(width: 10),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }

  String _priceLabel(ArtworkState state) {
    final min = state.precioMinFiltro;
    final max = state.precioMaxFiltro;
    if (min == null && max == null) return 'Precio';
    if (min != null && max != null) return 'Precio: $min - $max';
    if (min != null) return 'Precio: desde $min';
    return 'Precio: hasta $max';
  }

  String _ordenLabel(String orden) {
    switch (orden) {
      case 'precio_asc':
        return 'Precio ↑';
      case 'precio_desc':
        return 'Precio ↓';
      case 'relevancia':
        return 'Relevancia';
      default:
        return 'Fecha';
    }
  }

  Future<void> _pickCategoria({
    required String? selected,
    required void Function(String?) onSelected,
  }) async {
    final value = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _PickerSheet(
          title: 'Categoría',
          items: kCategoriasNarino,
          selected: selected,
        );
      },
    );
    onSelected(value);
  }

  Future<void> _pickTecnica({
    required String? selected,
    required void Function(String?) onSelected,
  }) async {
    final value = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _PickerSheet(
          title: 'Técnica',
          items: kTecnicasNarino,
          selected: selected,
        );
      },
    );
    onSelected(value);
  }

  Future<void> _pickOrden({
    required String selected,
    required void Function(String) onSelected,
  }) async {
    final value = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final items = <String, String>{
          'fecha': 'Fecha',
          'precio_asc': 'Precio: menor a mayor',
          'precio_desc': 'Precio: mayor a menor',
          'relevancia': 'Relevancia',
        };
        return _PickerSheet(
          title: 'Ordenar por',
          items: items.keys.toList(),
          selected: selected,
          labelBuilder: (key) => items[key]!,
          allowClear: false,
        );
      },
    );
    if (value != null) onSelected(value);
  }

  Future<void> _pickPrecio({
    required double? min,
    required double? max,
    required void Function(double?, double?) onSelected,
  }) async {
    final result = await showModalBottomSheet<({double? min, double? max})?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _PriceSheet(min: min, max: max),
    );
    if (result != null) onSelected(result.min, result.max);
  }
}

class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({
    required this.artwork,
    required this.onTap,
    required this.onFavorite,
  });

  final ArtworkModel artwork;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final imageUrl = artwork.imagenes.isEmpty ? null : artwork.imagenes.first;
    final hasPrice = artwork.precio != null;

    return Material(
      color: AppColors.bgCardLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 92,
                  height: 92,
                  color: AppColors.bgSubtleLight,
                  child: imageUrl == null
                      ? const Icon(
                          Icons.image_outlined,
                          color: AppColors.textMutedLight,
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textMutedLight,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            artwork.titulo,
                            style: AppTypography.labelSemiBold(
                              color: AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: onFavorite,
                          icon: Icon(
                            artwork.esFavorito
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: artwork.esFavorito
                                ? AppColors.error
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      artwork.artistaNombre,
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Badge(text: artwork.categoria),
                        _Badge(text: '${artwork.cantidadFavoritos} fav'),
                        if (hasPrice) _Badge(text: '\$${artwork.precio}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.oroPalido,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTypography.caption(color: AppColors.obsidiana),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: AppTypography.labelMedium(color: AppColors.textPrimaryLight),
      ),
      onPressed: onTap,
      backgroundColor: selected ? AppColors.oroPalido : AppColors.bgCardLight,
      side: const BorderSide(color: AppColors.borderLight),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.selected,
    this.allowClear = true,
    this.labelBuilder,
  });

  final String title;
  final List<String> items;
  final String? selected;
  final bool allowClear;
  final String Function(String key)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.displaySemiBold(
                  color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 12),
            if (allowClear)
              ListTile(
                onTap: () => Navigator.of(context).pop(null),
                leading: const Icon(Icons.clear),
                title: const Text('Todos'),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item == selected;
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(item),
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? AppColors.oroAndino
                          : AppColors.textMutedLight,
                    ),
                    title: Text(labelBuilder?.call(item) ?? item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceSheet extends StatefulWidget {
  const _PriceSheet({required this.min, required this.max});

  final double? min;
  final double? max;

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(text: widget.min?.toString() ?? '');
    _maxCtrl = TextEditingController(text: widget.max?.toString() ?? '');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rango de precio',
              style: AppTypography.displaySemiBold(
                  color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Mínimo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Máximo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop((min: null, max: null)),
                  child: const Text('Limpiar'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    final min = double.tryParse(_minCtrl.text.trim());
                    final max = double.tryParse(_maxCtrl.text.trim());
                    Navigator.of(context).pop((min: min, max: max));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.oroAndino,
                    foregroundColor: AppColors.obsidiana,
                  ),
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style:
                  AppTypography.bodySmall(color: AppColors.textSecondaryLight),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Reintentar',
              style: AppTypography.labelSemiBold(color: AppColors.indigoNoche),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        6,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 116,
            decoration: BoxDecoration(
              color: AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            padding: const EdgeInsets.all(12),
            child: const Row(
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: ColoredBox(color: AppColors.bgSubtleLight),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      ColoredBox(
                        color: AppColors.bgSubtleLight,
                        child: SizedBox(height: 12, width: double.infinity),
                      ),
                      SizedBox(height: 10),
                      ColoredBox(
                        color: AppColors.bgSubtleLight,
                        child: SizedBox(height: 10, width: 160),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off,
              size: 40, color: AppColors.textMutedLight),
          const SizedBox(height: 10),
          Text(
            'No se encontraron obras con estos filtros.',
            style:
                AppTypography.labelSemiBold(color: AppColors.textPrimaryLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Intenta cambiar la búsqueda o limpiar los filtros.',
            style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
