import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/artwork_model.dart';
import '../providers/artwork_provider.dart';

// ─── Constantes ──────────────────────────────────────────────────────────────

const _kPagePadding = EdgeInsets.fromLTRB(20, 16, 20, 32);
const _kSectionRadius = 16.0;
const _kHeaderHeight = 340.0;

// ─── Pantalla principal ───────────────────────────────────────────────────────

class ArtworkDetailScreen extends ConsumerWidget {
  const ArtworkDetailScreen({super.key, required this.artworkId});

  final int artworkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncArtwork = ref.watch(artworkDetailProvider(artworkId));

    return asyncArtwork.when(
      data: (artwork) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _ArtworkDetailBody(artwork: artwork),
      ),
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const _LoadingView(),
      ),
      error: (e, _) => _ErrorView(message: e.toString()),
    );
  }
}

// ─── Vistas de estado ─────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
        strokeWidth: 2,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Detalle',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTypography.bodyMedium(color: textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cuerpo principal ─────────────────────────────────────────────────────────

class _ArtworkDetailBody extends ConsumerStatefulWidget {
  const _ArtworkDetailBody({required this.artwork});

  final ArtworkModel artwork;

  @override
  ConsumerState<_ArtworkDetailBody> createState() => _ArtworkDetailBodyState();
}

class _ArtworkDetailBodyState extends ConsumerState<_ArtworkDetailBody>
    with SingleTickerProviderStateMixin {
  int _imagenActiva = 0;
  late bool _esFavorito;
  late int _cantidadFavoritos;
  late final AnimationController _favAnimController;
  late final Animation<double> _favScale;

  @override
  void initState() {
    super.initState();
    _esFavorito = widget.artwork.esFavorito;
    _cantidadFavoritos = widget.artwork.cantidadFavoritos;

    _favAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _favScale = Tween<double>(begin: 1, end: 1.3).animate(
      CurvedAnimation(parent: _favAnimController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _favAnimController.dispose();
    super.dispose();
  }

  // ─── Acciones ───────────────────────────────────────────────────────────────

  void _toggleFavorito() {
    HapticFeedback.lightImpact();
    _favAnimController.forward().then((_) => _favAnimController.reverse());
    setState(() {
      _esFavorito = !_esFavorito;
      _cantidadFavoritos =
          (_cantidadFavoritos + (_esFavorito ? 1 : -1)).clamp(0, 1 << 30);
    });
    ref.read(artworkProvider.notifier).toggleFavorite(widget.artwork.id);
  }

  Future<void> _openZoom(BuildContext context) async {
    final images = widget.artwork.imagenes;
    if (images.isEmpty) return;

    final controller = PageController(initialPage: _imagenActiva);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => _ZoomGallery(
        images: images,
        controller: controller,
        initialIndex: _imagenActiva,
        onPageChanged: (i) => setState(() => _imagenActiva = i),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar obra'),
        content: const Text('¿Seguro que deseas eliminar esta obra?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;
    final role = ref.watch(currentUserRoleProvider).value;
    final userId = ref.watch(currentUserIdProvider).value;
    final canManage =
        role == 'admin' || (userId != null && userId == artwork.artistaId);

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, artwork, canManage),
        SliverPadding(
          padding: _kPagePadding,
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderRow(
                  artwork: artwork,
                  esFavorito: _esFavorito,
                  cantidadFavoritos: _cantidadFavoritos,
                  favScale: _favScale,
                  onFavTap: _toggleFavorito,
                ),
                const SizedBox(height: 20),
                _TechnicalCard(artwork: artwork),
                if (artwork.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DescriptionCard(descripcion: artwork.descripcion),
                ],
                const SizedBox(height: 12),
                _ArtistCard(artwork: artwork),
                const SizedBox(height: 20),
                _ActionButton(artwork: artwork),
                if (artwork.estado == 'en_subasta') ...[
                  const SizedBox(height: 12),
                  const _AuctionBanner(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    ArtworkModel artwork,
    bool canManage,
  ) {
    return SliverAppBar(
      expandedHeight: _kHeaderHeight,
      pinned: true,
      backgroundColor: AppColors.obsidiana,
      foregroundColor: Colors.white,
      leading: const BackButton(color: Colors.white),
      title: Text(
        artwork.titulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSemiBold(color: Colors.white),
      ),
      centerTitle: false,
      actions: [
        ScaleTransition(
          scale: _favScale,
          child: IconButton(
            icon: Icon(
              _esFavorito ? Icons.favorite : Icons.favorite_outline,
              color: _esFavorito ? Colors.red[300] : Colors.white,
            ),
            onPressed: _toggleFavorito,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () => _showShareSheet(context, artwork),
        ),
        if (canManage)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'edit') {
                context.push('/artworks/${artwork.id}/edit');
              } else if (value == 'delete') {
                final ok = await _confirmDelete(context);
                if (!ok) return;
                final deleted = await ref
                    .read(artworkProvider.notifier)
                    .deleteArtwork(artwork.id);
                if (!context.mounted) return;
                if (deleted) {
                  context.pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No se pudo eliminar la obra.')),
                  );
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _GalleryHeader(
          artwork: artwork,
          imagenActiva: _imagenActiva,
          onTap: () => _openZoom(context),
          onDotTap: (i) => setState(() => _imagenActiva = i),
        ),
      ),
    );
  }
}

// ─── Galería de imágenes en AppBar ────────────────────────────────────────────

class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({
    required this.artwork,
    required this.imagenActiva,
    required this.onTap,
    required this.onDotTap,
  });

  final ArtworkModel artwork;
  final int imagenActiva;
  final VoidCallback onTap;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    final imagenes = artwork.imagenes;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: onTap,
          child: imagenes.isNotEmpty
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: CachedNetworkImage(
                    key: ValueKey(imagenes[imagenActiva]),
                    imageUrl: imagenes[imagenActiva],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const _ImagePlaceholder(),
                    errorWidget: (_, __, ___) => const _ImageError(),
                  ),
                )
              : const _ImageEmpty(),
        ),

        // Gradiente superior e inferior
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC000000),
                Color(0x00000000),
                Color(0xBB000000),
              ],
              stops: [0, 0.4, 1],
            ),
          ),
        ),

        // Botón "Ver en zoom"
        Positioned(
          right: 14,
          bottom: imagenes.length > 1 ? 38 : 14,
          child: _ZoomButton(onTap: onTap),
        ),

        // Indicador de páginas
        if (imagenes.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: _PageDots(
              count: imagenes.length,
              activeIndex: imagenActiva,
              onTap: onDotTap,
            ),
          ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.zoom_out_map, size: 15, color: Colors.white),
              const SizedBox(width: 5),
              Text('Ver', style: AppTypography.caption(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.activeIndex,
    required this.onTap,
  });

  final int count;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 20 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isActive ? AppColors.oroClaro : Colors.white54,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Galería zoom ─────────────────────────────────────────────────────────────

class _ZoomGallery extends StatefulWidget {
  const _ZoomGallery({
    required this.images,
    required this.controller,
    required this.initialIndex,
    required this.onPageChanged,
  });

  final List<String> images;
  final PageController controller;
  final int initialIndex;
  final ValueChanged<int> onPageChanged;

  @override
  State<_ZoomGallery> createState() => _ZoomGalleryState();
}

class _ZoomGalleryState extends State<_ZoomGallery> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_current + 1} / ${widget.images.length}',
          style: AppTypography.labelSemiBold(color: Colors.white),
        ),
      ),
      body: PhotoViewGallery.builder(
        pageController: widget.controller,
        itemCount: widget.images.length,
        builder: (_, index) => PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(widget.images[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3.0,
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        onPageChanged: (i) {
          setState(() => _current = i);
          widget.onPageChanged(i);
        },
        loadingBuilder: (_, __) => const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

// ─── Secciones del detalle ────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.artwork,
    required this.esFavorito,
    required this.cantidadFavoritos,
    required this.favScale,
    required this.onFavTap,
  });

  final ArtworkModel artwork;
  final bool esFavorito;
  final int cantidadFavoritos;
  final Animation<double> favScale;
  final VoidCallback onFavTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final pillTierraBg =
        isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    final pillTierraFg = isDark ? AppColors.tierraDark : AppColors.tierraProfunda;
    final pillIndigoBg =
        isDark ? AppColors.indigoNoche.withValues(alpha: 0.25) : AppColors.indigoPalido;
    final pillIndigoFg =
        isDark ? AppColors.indigoDark : AppColors.indigoNoche;
    final pillMutedBg =
        isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    label: artwork.categoria,
                    background: pillTierraBg,
                    foreground: pillTierraFg,
                  ),
                  if (artwork.estado != 'disponible')
                    _Pill(
                      label: artwork.estado == 'en_subasta'
                          ? 'En subasta'
                          : 'Vendida',
                      background: artwork.estado == 'en_subasta'
                          ? pillIndigoBg
                          : pillMutedBg,
                      foreground: artwork.estado == 'en_subasta'
                          ? pillIndigoFg
                          : textMuted,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onFavTap,
              child: ScaleTransition(
                scale: favScale,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: esFavorito
                        ? Colors.red.withAlpha(18)
                        : bgCard,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: esFavorito
                          ? Colors.red.shade200
                          : border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        esFavorito ? Icons.favorite : Icons.favorite_outline,
                        color: esFavorito ? Colors.red : textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$cantidadFavoritos',
                        style: AppTypography.caption(color: textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          artwork.titulo,
          style: AppTypography.displaySemiBold(color: textPrimary),
        ),
        const SizedBox(height: 6),
        if (artwork.precio != null)
          Text(
            '${_formatCOP(artwork.precio!)} COP',
            style: AppTypography.labelSemiBold(color: AppColors.oroAndino),
          )
        else
          Text(
            'Obra para exhibición — sin precio',
            style: AppTypography.bodyMedium(color: textMuted),
          ),
      ],
    );
  }
}

class _TechnicalCard extends StatelessWidget {
  const _TechnicalCard({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _InfoRow('Categoría', artwork.categoria),
      if (artwork.tecnica != null) _InfoRow('Técnica', artwork.tecnica!),
      if (artwork.dimensiones != null)
        _InfoRow('Dimensiones', artwork.dimensiones!),
      if (artwork.anio != null) _InfoRow('Año', artwork.anio.toString()),
    ];

    return _SectionCard(
      title: 'Ficha técnica',
      icon: Icons.info_outline,
      child: Column(children: rows),
    );
  }
}

class _DescriptionCard extends StatefulWidget {
  const _DescriptionCard({required this.descripcion});

  final String descripcion;

  @override
  State<_DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<_DescriptionCard> {
  bool _expanded = false;
  static const _maxLines = 4;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final linkColor = isDark ? AppColors.tierraDark : AppColors.tierraProfunda;

    return _SectionCard(
      title: 'Descripción',
      icon: Icons.notes_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCrossFade(
            firstChild: Text(
              widget.descripcion,
              style: AppTypography.bodyMedium(color: textPrimary),
              maxLines: _maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              widget.descripcion,
              style: AppTypography.bodyMedium(color: textPrimary),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          if (widget.descripcion.length > 200) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Ver menos' : 'Ver más',
                style: AppTypography.caption(color: linkColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final avatarBg = isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    final avatarFg = isDark ? AppColors.tierraDark : AppColors.tierraProfunda;
    final linkColor = isDark ? AppColors.tierraDark : AppColors.tierraProfunda;

    return _SectionCard(
      title: 'Artista',
      icon: Icons.person_outline,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_kSectionRadius - 4),
          onTap: () => context.go('/profile'),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: avatarBg,
                  backgroundImage: artwork.artistaFoto != null
                      ? NetworkImage(artwork.artistaFoto!)
                      : null,
                  child: artwork.artistaFoto == null
                      ? Text(
                          artwork.artistaNombre.isNotEmpty
                              ? artwork.artistaNombre[0].toUpperCase()
                              : '?',
                          style: AppTypography.displaySemiBold(color: avatarFg),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.artistaNombre,
                        style: AppTypography.labelSemiBold(color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ver perfil completo',
                        style: AppTypography.caption(color: linkColor),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    if (artwork.estado != 'disponible' || artwork.precio == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Carrito disponible próximamente')),
          );
        },
        icon: const Icon(Icons.shopping_cart_outlined),
        label: Text(
          'Agregar al carrito',
          style: AppTypography.labelSemiBold(color: Colors.white),
        ),
      ),
    );
  }
}

// ─── Widgets reutilizables ────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.caption(color: textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium(color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: AppTypography.caption(color: foreground)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(_kSectionRadius),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: textMuted),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: AppTypography.labelSemiBold(color: textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AuctionBanner extends StatelessWidget {
  const _AuctionBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerBg = isDark
        ? AppColors.indigoNoche.withValues(alpha: 0.25)
        : AppColors.indigoPalido;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final indigoFg = isDark ? AppColors.indigoDark : AppColors.indigoNoche;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.gavel_outlined, color: indigoFg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esta obra está en subasta. Revisa el estado de la puja en el módulo de Subastas.',
              style: AppTypography.bodySmall(color: indigoFg),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Imágenes placeholder ─────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    return Container(
      color: bgSubtle,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final iconColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      color: bgSubtle,
      child: Icon(Icons.image_outlined, size: 60, color: iconColor),
    );
  }
}

class _ImageEmpty extends StatelessWidget {
  const _ImageEmpty();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final iconColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      color: bgSubtle,
      child: Icon(Icons.palette_outlined, size: 60, color: iconColor),
    );
  }
}

// ─── Share sheet ──────────────────────────────────────────────────────────────

Future<void> _showShareSheet(BuildContext context, ArtworkModel artwork) async {
  final url = 'https://narinocultura.app/artworks/${artwork.id}';
  final texto =
      '🎨 ${artwork.titulo} — por ${artwork.artistaNombre}\n\nDescubre esta obra en Nariño Cultura:\n$url';

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bgCard = Theme.of(context).cardTheme.color ??
      Theme.of(context).colorScheme.surface;
  final handleColor =
      isDark ? AppColors.borderDark : AppColors.borderLight;
  final titleColor =
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Compartir obra',
            style: AppTypography.displaySemiBold(color: titleColor),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShareOption(
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () {
                  _shareToWhatsApp(texto);
                  Navigator.pop(context);
                },
              ),
              _ShareOption(
                icon: Icons.facebook_outlined,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                onTap: () {
                  _shareToFacebook(url);
                  Navigator.pop(context);
                },
              ),
              _ShareOption(
                icon: Icons.alternate_email,
                label: 'X / Twitter',
                color: Colors.black,
                onTap: () {
                  _shareToX(url, texto);
                  Navigator.pop(context);
                },
              ),
              _ShareOption(
                icon: Icons.more_horiz,
                label: 'Más',
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                onTap: () {
                  Share.share(texto);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enlace copiado al portapapeles')),
              );
            },
            icon: const Icon(Icons.link),
            label: const Text('Copiar enlace'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withAlpha(12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.caption(color: textMuted)),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatCOP(double value) {
  final raw = value.toStringAsFixed(0);
  return '\$${raw.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

Future<void> _shareToWhatsApp(String texto) async {
  final encoded = Uri.encodeComponent(texto);
  final schemeUri = Uri.parse('whatsapp://send?text=$encoded');
  if (await launchUrl(schemeUri, mode: LaunchMode.externalApplication)) return;
  final webUri = Uri.parse('https://wa.me/?text=$encoded');
  if (!await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
    await Share.share(texto);
  }
}

Future<void> _shareToFacebook(String url) async {
  final uri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    await Share.share(url);
  }
}

Future<void> _shareToX(String url, String texto) async {
  final uri = Uri.parse(
      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(texto)}');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    await Share.share('$texto\n$url');
  }
}
