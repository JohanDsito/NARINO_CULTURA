import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/nc_tap_target.dart';
import '../../../domain/artwork_model.dart';
import '../../../domain/artwork_state.dart';
import '../../providers/artwork_provider.dart';
import 'category_chip.dart';

/// Fila de chips: "Filtros" (con contador) + categorías reales del backend.
class CategoryChips extends ConsumerWidget {
  const CategoryChips({
    super.key,
    required this.state,
    required this.onFilterTap,
  });

  final ArtworkState state;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final categorias =
        ref.watch(categoriesProvider).valueOrNull ?? const <CategoryModel>[];
    final activos = state.filtrosPanelActivos;

    return SizedBox(
      height: kNcMinTapTarget, // MO-ACC-04; el chip se ve de 40
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          CategoryChip(
            label: activos > 0 ? 'Filtros · $activos' : 'Filtros',
            icon: Icons.tune_rounded,
            selected: activos > 0,
            accent: nc.azulA,
            onTap: onFilterTap,
          ),
          const SizedBox(width: 8),
          CategoryChip(
            label: 'Todas',
            selected: state.categoriaFiltro == null,
            accent: nc.catalogo,
            onTap: () => ref.read(artworkProvider.notifier).setCategoria(null),
          ),
          for (final cat in categorias) ...[
            const SizedBox(width: 8),
            CategoryChip(
              label: cat.displayName,
              selected: state.categoriaFiltro == cat.id.toString(),
              accent: nc.catalogo,
              onTap: () {
                final value = cat.id.toString();
                ref.read(artworkProvider.notifier).setCategoria(
                    state.categoriaFiltro == value ? null : value);
              },
            ),
          ],
        ],
      ),
    );
  }
}
