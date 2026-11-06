import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/artwork_model.dart';
import '../../../domain/artwork_state.dart';
import '../../providers/artwork_provider.dart';

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
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: activos > 0 ? 'Filtros · $activos' : 'Filtros',
            icon: Icons.tune_rounded,
            selected: activos > 0,
            accent: nc.azulA,
            onTap: onFilterTap,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Todas',
            selected: state.categoriaFiltro == null,
            accent: nc.catalogo,
            onTap: () => ref.read(artworkProvider.notifier).setCategoria(null),
          ),
          for (final cat in categorias) ...[
            const SizedBox(width: 8),
            _Chip(
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final NcAccent accent;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fg = selected ? accent.onFill : nc.textPrimary;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? accent.fill : nc.bgGlass,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? accent.fill : nc.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTypography.labelMedium(color: fg)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
