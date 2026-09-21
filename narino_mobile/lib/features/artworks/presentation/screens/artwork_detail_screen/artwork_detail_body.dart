import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/providers/user_role_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../marketplace/domain/marketplace_state.dart';
import '../../../../marketplace/presentation/providers/favorites_provider.dart';
import '../../../domain/artwork_model.dart';
import '../../providers/artwork_provider.dart';
import 'action_button.dart';
import 'artist_card.dart';
import 'auction_banner.dart';
import 'description_card.dart';
import 'gallery_header.dart';
import 'header_row.dart';
import 'share_option.dart';
import 'technical_card.dart';
import 'zoom_gallery.dart';

// ─── Constantes ──────────────────────────────────────────────────────────────

const _kPagePadding = EdgeInsets.fromLTRB(20, 16, 20, 32);
const _kHeaderHeight = 340.0;

// ─── Cuerpo principal ─────────────────────────────────────────────────────────

class ArtworkDetailBody extends ConsumerStatefulWidget {
  const ArtworkDetailBody({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  ConsumerState<ArtworkDetailBody> createState() => _ArtworkDetailBodyState();
}

class _ArtworkDetailBodyState extends ConsumerState<ArtworkDetailBody>
    with SingleTickerProviderStateMixin {
  int _imagenActiva = 0;
  late bool _esFavorito;
  late final AnimationController _favAnimController;
  late final Animation<double> _favScale;

  @override
  void initState() {
    super.initState();
    // Use the favorites provider as source of truth — the catalog API never
    // returns es_favorito so artwork.esFavorito is always false.
    _esFavorito =
        ref.read(favoritesProvider).isFavorite(widget.artwork.id);

    _favAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _favScale = Tween<double>(begin: 1, end: 1.3).animate(
      CurvedAnimation(parent: _favAnimController, curve: Curves.easeOutBack),
    );

    // If favorites haven't been fetched yet (e.g. user opened the detail
    // without visiting the profile tab), load them now so _esFavorito is
    // correct after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = ref.read(favoritesProvider).status;
      if (status == MarketplaceStatus.initial) {
        ref.read(favoritesProvider.notifier).loadFavorites().then((_) {
          if (mounted) {
            setState(() {
              _esFavorito = ref
                  .read(favoritesProvider)
                  .isFavorite(widget.artwork.id);
            });
          }
        });
      }
    });
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

    // Optimistic UI update.
    setState(() => _esFavorito = !_esFavorito);

    // FavoritesNotifier checks local state first (isFav → remove, else add),
    // so it can never create a duplicate like or silently delete an existing one.
    ref
        .read(favoritesProvider.notifier)
        .toggleFavorite(widget.artwork.id)
        .then((_) {
      // Sync displayed state with the authoritative provider result.
      if (mounted) {
        setState(() {
          _esFavorito =
              ref.read(favoritesProvider).isFavorite(widget.artwork.id);
        });
      }
    });
  }

  Future<void> _openZoom(BuildContext context) async {
    final images = widget.artwork.imagenes;
    if (images.isEmpty) return;

    final controller = PageController(initialPage: _imagenActiva);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => ZoomGallery(
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
        role == 'admin' || (userId != null && userId.toString() == artwork.artistaId);

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, artwork, canManage),
        SliverPadding(
          padding: _kPagePadding,
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderRow(
                  artwork: artwork,
                  esFavorito: _esFavorito,
                  favScale: _favScale,
                  onFavTap: _toggleFavorito,
                ),
                const SizedBox(height: 20),
                TechnicalCard(artwork: artwork),
                if (artwork.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DescriptionCard(descripcion: artwork.descripcion),
                ],
                const SizedBox(height: 12),
                ArtistCard(artwork: artwork),
                const SizedBox(height: 20),
                ActionButton(artwork: artwork),
                if (artwork.estado == 'en_subasta') ...[
                  const SizedBox(height: 12),
                  const AuctionBanner(),
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
        background: GalleryHeader(
          artwork: artwork,
          imagenActiva: _imagenActiva,
          onTap: () => _openZoom(context),
          onDotTap: (i) => setState(() => _imagenActiva = i),
        ),
      ),
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
              ShareOption(
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () {
                  _shareToWhatsApp(texto);
                  Navigator.pop(context);
                },
              ),
              ShareOption(
                icon: Icons.facebook_outlined,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                onTap: () {
                  _shareToFacebook(url);
                  Navigator.pop(context);
                },
              ),
              ShareOption(
                icon: Icons.alternate_email,
                label: 'X / Twitter',
                color: Colors.black,
                onTap: () {
                  _shareToX(url, texto);
                  Navigator.pop(context);
                },
              ),
              ShareOption(
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
