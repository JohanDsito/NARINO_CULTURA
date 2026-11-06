import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/artwork_state.dart';
import '../../providers/artwork_provider.dart';
import 'artwork_card.dart';

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 14,
  childAspectRatio: 0.64,
);

/// Cuerpo del catálogo como sliver: esqueletos, error, vacío o grilla.
class CatalogBody extends ConsumerWidget {
  const CatalogBody({super.key, required this.state});

  final ArtworkState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.artworks.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: _gridDelegate,
          delegate: SliverChildBuilderDelegate(
            (_, __) => const _SkeletonCard(),
            childCount: 6,
          ),
        ),
      );
    }
    if (state.hasError) {
      return SliverToBoxAdapter(
        child: _StateMessage(
          icon: Icons.cloud_off_rounded,
          accent: context.nc.tomateA,
          title: 'No pudimos cargar el catálogo',
          message: state.errorMessage!,
          actionLabel: 'Reintentar',
          onAction: () => ref.read(artworkProvider.notifier).loadCatalog(),
        ),
      );
    }
    if (state.artworks.isEmpty) {
      final filtros = state.hayFiltrosActivos;
      return SliverToBoxAdapter(
        child: _StateMessage(
          icon: Icons.palette_outlined,
          accent: context.nc.catalogo,
          title: filtros ? 'Nada con esos filtros' : 'Aún no hay obras',
          message: filtros
              ? 'Prueba con otra categoría o quita algunos filtros.'
              : 'Cuando los artistas publiquen, sus obras aparecerán aquí.',
          actionLabel: filtros ? 'Limpiar filtros' : null,
          onAction: filtros
              ? () => ref.read(artworkProvider.notifier).limpiarFiltros()
              : null,
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: _gridDelegate,
        delegate: SliverChildBuilderDelegate(
          (_, i) => CatalogArtworkCard(artwork: state.artworks[i]),
          childCount: state.artworks.length,
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    reduce ? _c.stop() : _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final block = nc.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: block,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween(begin: 0.55, end: 1.0).animate(_c),
        child: Container(
          decoration: BoxDecoration(
            color: nc.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: nc.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Container(color: block)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(110, 12),
                    const SizedBox(height: 8),
                    bar(70, 10),
                    const SizedBox(height: 10),
                    bar(60, 12),
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

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final NcAccent accent;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: NcCard(
        child: Column(
          children: [
            NcAccentIcon(icon: icon, accent: accent, size: 64, glow: true),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTypography.displaySemiBold(color: nc.textPrimary)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(color: nc.textSecondary)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              NcPrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
