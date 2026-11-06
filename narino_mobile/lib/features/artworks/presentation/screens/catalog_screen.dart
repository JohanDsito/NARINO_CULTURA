import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../marketplace/domain/marketplace_state.dart';
import '../../../marketplace/presentation/providers/favorites_provider.dart';
import '../../domain/artwork_state.dart';
import '../providers/artwork_provider.dart';
import 'catalog_screen/catalog_body.dart';
import 'catalog_screen/category_chips.dart';
import 'catalog_screen/filtros_sheet.dart';

/// Catálogo de obras (acento magenta: artes plásticas).
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = ref.read(artworkProvider).busqueda;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(artworkProvider.notifier).loadCatalog();
      if (ref.read(favoritesProvider).status == MarketplaceStatus.initial) {
        ref.read(favoritesProvider.notifier).loadFavorites();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Busca cuando la persona deja de escribir (antes: 1 petición por letra).
  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(artworkProvider.notifier).setBusqueda(value.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    setState(_searchCtrl.clear);
    ref.read(artworkProvider.notifier).setBusqueda('');
  }

  void _openFilters(ArtworkState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FiltrosSheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final state = ref.watch(artworkProvider);
    final role = ref.watch(currentUserRoleProvider).valueOrNull;
    final canPublish = role == 'artista' || role == 'admin';
    final top = MediaQuery.paddingOf(context).top + NcGlassHeader.contentHeight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: NcGlassHeader(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ARTES PLÁSTICAS',
                style: AppTypography.caption(color: nc.catalogo.ink)
                    .copyWith(letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text('Catálogo de Obras',
                style: AppTypography.displaySemiBold(color: nc.textPrimary)
                    .copyWith(fontSize: 19)),
          ],
        ),
        actions: [
          if (canPublish)
            NcIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Publicar obra',
              onPressed: () => context.push('/artworks/publish'),
            ),
        ],
      ),
      body: RefreshIndicator(
        edgeOffset: top,
        onRefresh: () => ref.read(artworkProvider.notifier).loadCatalog(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: top + 14)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SearchField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: CategoryChips(
                state: state,
                onFilterTap: () => _openFilters(state),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Text(
                  state.isLoading
                      ? 'Buscando obras…'
                      : state.totalResultados == 1
                          ? '1 obra'
                          : '${state.totalResultados} obras',
                  style: AppTypography.labelMedium(color: nc.textSecondary),
                ),
              ),
            ),
            CatalogBody(state: state),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(99),
      borderSide: BorderSide(color: nc.border),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar obras, técnicas o artistas',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar búsqueda',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              ),
        fillColor: nc.bgGlass,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: pill,
        enabledBorder: pill,
        focusedBorder: pill.copyWith(
          borderSide: BorderSide(color: nc.catalogo.fill, width: 1.5),
        ),
      ),
    );
  }
}
