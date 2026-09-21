import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/artwork_state.dart';
import '../providers/artwork_provider.dart';
import '../../../marketplace/domain/marketplace_state.dart';
import '../../../marketplace/presentation/providers/favorites_provider.dart';
import 'catalog_screen/catalog_body.dart';
import 'catalog_screen/category_chips.dart';
import 'catalog_screen/filtros_sheet.dart';
import 'catalog_screen/results_count.dart';
import 'catalog_screen/search_bar.dart';

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
      if (ref.read(favoritesProvider).status == MarketplaceStatus.initial) {
        ref.read(favoritesProvider.notifier).loadFavorites();
      }
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
      builder: (_) => FiltrosSheet(state: state),
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
              onPressed: () => context.push('/artworks/publish'),
            ),
        ],
      ),
      body: Column(
        children: [
          CatalogSearchBar(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),
          CategoryChips(
            state: state,
            onFilterTap: () => _openFilters(context, state),
          ),
          if (state.status == ArtworkStatus.loaded)
            ResultsCount(count: state.totalResultados),
          Expanded(
            child: RefreshIndicator(
              // ✅ FIX: color hardcodeado → cs.primary
              color: cs.primary,
              onRefresh: () async =>
                  ref.read(artworkProvider.notifier).loadCatalog(),
              child: CatalogBody(state: state),
            ),
          ),
        ],
      ),
    );
  }
}
