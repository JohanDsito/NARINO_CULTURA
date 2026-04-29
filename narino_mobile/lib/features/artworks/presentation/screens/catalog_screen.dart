import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(artworkProvider.notifier).loadCatalog();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _abrirFiltros(BuildContext context, ArtworkState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FiltrosSheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(artworkProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        title: Text(
          'Catálogo',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.oroClaro),
            tooltip: 'Publicar obra',
            onPressed: () => context.go('/artworks/publish'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style:
                  AppTypography.bodyMedium(color: AppColors.textPrimaryLight),
              decoration: InputDecoration(
                hintText: 'Buscar por título, artista o técnica...',
                prefixIcon: const Icon(Icons.search_outlined),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(_searchCtrl.clear);
                          ref.read(artworkProvider.notifier).setBusqueda('');
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {});
                ref.read(artworkProvider.notifier).setBusqueda(v);
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_outlined,
                          size: 14,
                          color: state.hayFiltrosActivos
                              ? AppColors.tierraProfunda
                              : AppColors.textMutedLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          state.hayFiltrosActivos ? 'Filtros •' : 'Filtros',
                          style: AppTypography.caption(
                            color: state.hayFiltrosActivos
                                ? AppColors.tierraProfunda
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                    selected: state.hayFiltrosActivos,
                    onSelected: (_) => _abrirFiltros(context, state),
                    backgroundColor: AppColors.bgSubtleLight,
                    selectedColor: AppColors.tierraPalida,
                    checkmarkColor: Colors.transparent,
                    side: BorderSide(
                      color: state.hayFiltrosActivos
                          ? AppColors.tierraProfunda
                          : AppColors.borderLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                ...kCategoriasNarino.take(8).map((cat) {
                  final isSelected = state.categoriaFiltro == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        cat,
                        style: AppTypography.caption(
                          color: isSelected
                              ? AppColors.tierraProfunda
                              : AppColors.textMutedLight,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => ref
                          .read(artworkProvider.notifier)
                          .setCategoria(isSelected ? null : cat),
                      backgroundColor: AppColors.bgSubtleLight,
                      selectedColor: AppColors.tierraPalida,
                      checkmarkColor: Colors.transparent,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.tierraProfunda
                            : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          if (state.status == ArtworkStatus.loaded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${state.totalResultados} obras encontradas',
                  style: AppTypography.caption(color: AppColors.textMutedLight),
                ),
              ),
            ),
          Expanded(child: _buildBody(state, context)),
        ],
      ),
    );
  }

  Widget _buildBody(ArtworkState state, BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.tierraProfunda),
      );
    }
    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.errorMessage!,
              style: AppTypography.bodyMedium(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(artworkProvider.notifier).loadCatalog(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (state.artworks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.palette_outlined,
              size: 56,
              color: AppColors.borderLight,
            ),
            const SizedBox(height: 12),
            Text(
              'No se encontraron obras',
              style: AppTypography.bodyMedium(color: AppColors.textMutedLight),
            ),
            if (state.hayFiltrosActivos) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.read(artworkProvider.notifier).limpiarFiltros(),
                child: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: state.artworks.length,
      itemBuilder: (context, i) => _ArtworkCard(artwork: state.artworks[i]),
    );
  }
}

class _ArtworkCard extends ConsumerWidget {
  const _ArtworkCard({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.go('/artworks/${artwork.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  artwork.imagenes.isNotEmpty
                      ? Image.network(
                          artwork.imagenes.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.bgSubtleLight,
                            child: const Icon(
                              Icons.image_outlined,
                              color: AppColors.borderLight,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.bgSubtleLight,
                          child: const Icon(
                            Icons.palette_outlined,
                            color: AppColors.borderLight,
                            size: 32,
                          ),
                        ),
                  if (artwork.estado != 'disponible')
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: artwork.estado == 'en_subasta'
                              ? AppColors.indigoNoche
                              : AppColors.textMutedLight,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          artwork.estado == 'en_subasta'
                              ? 'En subasta'
                              : 'Vendida',
                          style: AppTypography.caption(color: Colors.white),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => ref
                          .read(artworkProvider.notifier)
                          .toggleFavorite(artwork.id),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          artwork.esFavorito
                              ? Icons.favorite
                              : Icons.favorite_outline,
                          color: artwork.esFavorito
                              ? Colors.red
                              : AppColors.textMutedLight,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.titulo,
                      style: AppTypography.labelSemiBold(
                        color: AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artwork.artistaNombre,
                      style: AppTypography.caption(
                          color: AppColors.textMutedLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    artwork.precio != null
                        ? Text(
                            _formatCOP(artwork.precio!),
                            style: AppTypography.labelSemiBold(
                              color: AppColors.oroAndino,
                            ),
                          )
                        : Text(
                            'Exhibición',
                            style: AppTypography.caption(
                              color: AppColors.textMutedLight,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCOP(double value) {
  final raw = value.toStringAsFixed(0);
  final formatted = raw.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return '\$$formatted';
}

class _FiltrosSheet extends ConsumerStatefulWidget {
  const _FiltrosSheet({required this.state});

  final ArtworkState state;

  @override
  ConsumerState<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends ConsumerState<_FiltrosSheet> {
  String? _categoria;
  String? _tecnica;
  String _orden = 'fecha';
  final _precioMinCtrl = TextEditingController();
  final _precioMaxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoria = widget.state.categoriaFiltro;
    _tecnica = widget.state.tecnicaFiltro;
    _orden = widget.state.ordenarPor;
    if (widget.state.precioMinFiltro != null) {
      _precioMinCtrl.text = widget.state.precioMinFiltro!.toStringAsFixed(0);
    }
    if (widget.state.precioMaxFiltro != null) {
      _precioMaxCtrl.text = widget.state.precioMaxFiltro!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _precioMinCtrl.dispose();
    _precioMaxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Filtros',
              style: AppTypography.displaySemiBold(
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Categoría',
              style: AppTypography.labelMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _categoria,
              hint: Text(
                'Todas',
                style:
                    AppTypography.bodyMedium(color: AppColors.textMutedLight),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...kCategoriasNarino
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (v) => setState(() => _categoria = v),
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Técnica',
              style: AppTypography.labelMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _tecnica,
              hint: Text(
                'Todas',
                style:
                    AppTypography.bodyMedium(color: AppColors.textMutedLight),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...kTecnicasNarino
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))),
              ],
              onChanged: (v) => setState(() => _tecnica = v),
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Rango de precio (COP)',
              style: AppTypography.labelMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _precioMinCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTypography.bodyMedium(
                      color: AppColors.textPrimaryLight,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Mínimo',
                      prefixText: r'$',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _precioMaxCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTypography.bodyMedium(
                      color: AppColors.textPrimaryLight,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Máximo',
                      prefixText: r'$',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Ordenar por',
              style: AppTypography.labelMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _orden,
              items: const [
                DropdownMenuItem(value: 'fecha', child: Text('Más recientes')),
                DropdownMenuItem(
                  value: 'precio_asc',
                  child: Text('Precio: menor a mayor'),
                ),
                DropdownMenuItem(
                  value: 'precio_desc',
                  child: Text('Precio: mayor a menor'),
                ),
                DropdownMenuItem(
                  value: 'relevancia',
                  child: Text('Más populares'),
                ),
              ],
              onChanged: (v) => setState(() => _orden = v ?? 'fecha'),
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(artworkProvider.notifier).limpiarFiltros();
                      Navigator.pop(context);
                    },
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final notifier = ref.read(artworkProvider.notifier);
                      notifier.setCategoria(_categoria);
                      notifier.setTecnica(_tecnica);
                      notifier.setOrden(_orden);
                      notifier.setRangoPrecio(
                        _precioMinCtrl.text.trim().isNotEmpty
                            ? double.tryParse(_precioMinCtrl.text.trim())
                            : null,
                        _precioMaxCtrl.text.trim().isNotEmpty
                            ? double.tryParse(_precioMaxCtrl.text.trim())
                            : null,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
