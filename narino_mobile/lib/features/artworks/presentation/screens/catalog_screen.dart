import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/artwork_model.dart';
import '../../domain/artwork_state.dart';
import '../providers/artwork_provider.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

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

  void _onSearchChanged(String value) {
    setState(() {});
    ref.read(artworkProvider.notifier).setBusqueda(value);
  }

  void _clearSearch() {
    setState(_searchCtrl.clear);
    ref.read(artworkProvider.notifier).setBusqueda('');
  }

  void _openFilters(BuildContext context, ArtworkState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // ✅ FIX: usar el color de superficie del tema en lugar de hardcodear
      backgroundColor: Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FiltrosSheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(artworkProvider);
    final role = ref.watch(currentUserRoleProvider).value;
    final canPublish = role == 'artista' || role == 'admin';
    // ✅ FIX: resolver colores del tema una sola vez
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana, // intencional (branding)
        foregroundColor: AppColors.oroClaro, // intencional (branding)
        title: Text(
          'Catálogo de Obras',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          if (canPublish)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.oroClaro),
              tooltip: 'Publicar obra',
              onPressed: () => context.go('/artworks/publish'),
            ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),
          _CategoryChips(
            state: state,
            onFilterTap: () => _openFilters(context, state),
          ),
          if (state.status == ArtworkStatus.loaded)
            _ResultsCount(count: state.totalResultados),
          Expanded(
            child: RefreshIndicator(
              // ✅ FIX: color hardcodeado → cs.primary
              color: cs.primary,
              onRefresh: () async =>
                  ref.read(artworkProvider.notifier).loadCatalog(),
              child: _CatalogBody(state: state),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Barra de búsqueda ────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final fillColor = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        style: AppTypography.bodyMedium(color: textPrimary),
        decoration: InputDecoration(
          hintText: 'Buscar por título, artista o técnica...',
          hintStyle: AppTypography.bodyMedium(color: textMuted),
          // ✅ FIX: añadir filled + fillColor para que el fondo sea coherente
          filled: true,
          fillColor: fillColor,
          prefixIcon: Icon(Icons.search_outlined, color: textMuted),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: textMuted),
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Chips de categoría ───────────────────────────────────────────────────────

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({
    required this.state,
    required this.onFilterTap,
  });

  final ArtworkState state;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    // ✅ FIX: selectedColor del chip resuelto desde el tema en lugar de color fijo
    final chipSelectedBg =
        isDark ? cs.primary.withValues(alpha: 0.18) : AppColors.tierraPalida;

    return SizedBox(
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
                    color: state.hayFiltrosActivos ? cs.primary : textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.hayFiltrosActivos ? 'Filtros •' : 'Filtros',
                    style: AppTypography.caption(
                      color: state.hayFiltrosActivos ? cs.primary : textMuted,
                    ),
                  ),
                ],
              ),
              selected: state.hayFiltrosActivos,
              onSelected: (_) => onFilterTap(),
              backgroundColor: bgSubtle,
              selectedColor: chipSelectedBg,
              checkmarkColor: Colors.transparent,
              side: BorderSide(
                color: state.hayFiltrosActivos ? cs.primary : border,
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
                    color: isSelected ? cs.primary : textMuted,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => ref
                    .read(artworkProvider.notifier)
                    .setCategoria(isSelected ? null : cat),
                backgroundColor: bgSubtle,
                selectedColor: chipSelectedBg,
                checkmarkColor: Colors.transparent,
                side: BorderSide(
                  color: isSelected ? cs.primary : border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Contador de resultados ───────────────────────────────────────────────────

class _ResultsCount extends StatelessWidget {
  const _ResultsCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$count obras encontradas',
          style: AppTypography.caption(color: textMuted),
        ),
      ),
    );
  }
}

// ─── Cuerpo del catálogo ──────────────────────────────────────────────────────

class _CatalogBody extends ConsumerWidget {
  const _CatalogBody({required this.state});

  final ArtworkState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) return const _LoadingGrid();
    if (state.hasError) return _ErrorBody(state: state);
    if (state.artworks.isEmpty) return _EmptyBody(state: state);

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 140),
        Center(
          child: CircularProgressIndicator(
            color: cs.primary,
            strokeWidth: 2,
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends ConsumerWidget {
  const _ErrorBody({required this.state});

  final ArtworkState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // ✅ FIX: ícono usaba AppColors.textMutedLight hardcodeado
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ FIX: color del ícono resuelto desde el tema
              Icon(Icons.cloud_off_outlined, size: 48, color: textMuted),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'Ha ocurrido un error',
                style: AppTypography.bodyMedium(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(artworkProvider.notifier).loadCatalog(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                // ✅ FIX: estilo del botón resuelto desde el tema
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyBody extends ConsumerWidget {
  const _EmptyBody({required this.state});

  final ArtworkState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 70),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ FIX: antes usaba `border` como color de ícono — semánticamente
              // incorrecto. Ahora usa textMuted que es el token correcto para
              // íconos decorativos en estado vacío.
              Icon(Icons.palette_outlined, size: 56, color: textMuted),
              const SizedBox(height: 14),
              Text(
                'No se encontraron obras',
                style: AppTypography.bodyMedium(color: textMuted),
              ),
              if (state.hayFiltrosActivos) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () =>
                      ref.read(artworkProvider.notifier).limpiarFiltros(),
                  icon: Icon(
                    Icons.filter_alt_off_outlined,
                    size: 18,
                    // ✅ FIX: color del ícono resuelto desde el tema
                    color: cs.primary,
                  ),
                  label: Text(
                    'Limpiar filtros',
                    style: AppTypography.bodySmall(color: cs.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tarjeta de obra ──────────────────────────────────────────────────────────

class _ArtworkCard extends ConsumerWidget {
  const _ArtworkCard({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return GestureDetector(
      onTap: () => context.go('/artworks/${artwork.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _CardImage(artwork: artwork)),
            Expanded(flex: 2, child: _CardInfo(artwork: artwork)),
          ],
        ),
      ),
    );
  }
}

class _CardImage extends ConsumerWidget {
  const _CardImage({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    // ✅ FIX: colores del badge de estado resueltos desde el tema
    final stateBg = artwork.estado == 'en_subasta'
        ? (isDark ? AppColors.indigoDark : AppColors.indigoNoche)
        : (isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight);
    final stateFg = artwork.estado == 'en_subasta' ? Colors.white : textMuted;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Imagen principal
        artwork.imagenes.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: artwork.imagenes.first,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: bgSubtle,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.primary),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: bgSubtle,
                  child: Icon(Icons.image_outlined, color: textMuted, size: 32),
                ),
              )
            : Container(
                color: bgSubtle,
                child: Icon(Icons.palette_outlined, color: textMuted, size: 32),
              ),

        // Badge de estado
        if (artwork.estado != 'disponible')
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stateBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                artwork.estado == 'en_subasta' ? 'En subasta' : 'Vendida',
                style: AppTypography.caption(color: stateFg),
              ),
            ),
          ),

        // Botón de favorito
        Positioned(
          top: 6,
          right: 6,
          child: _FavoriteButton(artwork: artwork),
        ),
      ],
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // ✅ FIX: fondo del botón usando tokens correctos en lugar de bgCardDark/Light
    final bg = isDark
        ? AppColors.bgSubtleDark.withAlpha(230)
        : AppColors.bgSubtleLight.withAlpha(230);
    final iconColor = artwork.esFavorito ? AppColors.error : cs.onSurface;
    final icon = artwork.esFavorito ? Icons.favorite : Icons.favorite_outline;

    return GestureDetector(
      onTap: () =>
          ref.read(artworkProvider.notifier).toggleFavorite(artwork.id),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            artwork.titulo,
            style: AppTypography.labelSemiBold(color: textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            artwork.artistaNombre,
            style: AppTypography.caption(color: textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          artwork.precio != null
              ? Text(
                  _formatCOP(artwork.precio!),
                  // oroAndino es intencional: color de precio es parte del branding
                  style:
                      AppTypography.labelSemiBold(color: AppColors.oroAndino),
                )
              : Text(
                  'Exhibición',
                  style: AppTypography.caption(color: textMuted),
                ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatCOP(double value) {
  final raw = value.toStringAsFixed(0);
  return '\$${raw.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  )}';
}

// ─── Sheet de filtros ─────────────────────────────────────────────────────────

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

  void _applyFilters() {
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
  }

  void _clearFilters() {
    ref.read(artworkProvider.notifier).limpiarFiltros();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    // ✅ FIX: color de las etiquetas de sección resuelto desde el tema
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: AppTypography.displaySemiBold(color: textPrimary),
                ),
                if (widget.state.hayFiltrosActivos)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                    label: const Text('Limpiar todo'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // ✅ FIX: _FilterLabel ahora recibe el color resuelto desde el tema
            _FilterLabel('Categoría', color: textSecondary),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _categoria,
              dropdownColor: theme.cardTheme.color ?? cs.surface,
              style: AppTypography.bodyMedium(color: textPrimary),
              hint: Text('Todas',
                  style: AppTypography.bodyMedium(color: textMuted)),
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
            _FilterLabel('Técnica', color: textSecondary),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _tecnica,
              dropdownColor: theme.cardTheme.color ?? cs.surface,
              style: AppTypography.bodyMedium(color: textPrimary),
              hint: Text('Todas',
                  style: AppTypography.bodyMedium(color: textMuted)),
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
            _FilterLabel('Rango de precio (COP)', color: textSecondary),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _precioMinCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTypography.bodyMedium(color: textPrimary),
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
                    style: AppTypography.bodyMedium(color: textPrimary),
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
            _FilterLabel('Ordenar por', color: textSecondary),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _orden,
              dropdownColor: theme.cardTheme.color ?? cs.surface,
              style: AppTypography.bodyMedium(color: textPrimary),
              items: const [
                DropdownMenuItem(value: 'fecha', child: Text('Más recientes')),
                DropdownMenuItem(
                    value: 'precio_asc', child: Text('Precio: menor a mayor')),
                DropdownMenuItem(
                    value: 'precio_desc', child: Text('Precio: mayor a menor')),
                DropdownMenuItem(
                    value: 'relevancia', child: Text('Más populares')),
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
                    onPressed: _clearFilters,
                    // ✅ FIX: color del OutlinedButton resuelto desde el tema
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary),
                    ),
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    // ✅ FIX: colores del ElevatedButton resueltos desde el tema
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    child: const Text('Aplicar filtros'),
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

// ✅ FIX: _FilterLabel recibe color como parámetro en lugar de hardcodear
// AppColors.textSecondaryLight, que rompía el dark mode
class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelMedium(color: color),
    );
  }
}
