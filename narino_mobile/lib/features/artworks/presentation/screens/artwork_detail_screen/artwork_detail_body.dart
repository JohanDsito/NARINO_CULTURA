import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/providers/user_role_provider.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../marketplace/domain/marketplace_state.dart';
import '../../../../marketplace/presentation/providers/favorites_provider.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../domain/artwork_model.dart';
import '../../providers/artwork_provider.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import 'detail_sections.dart';
import 'gallery_header.dart';
import 'share_option.dart';
import 'zoom_gallery.dart';

// ─── Constantes ──────────────────────────────────────────────────────────────

const _kHeaderHeight = 420.0;

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
  bool _perfilPedido = false;
  late bool _esFavorito;
  late final AnimationController _favAnimController;
  late final Animation<double> _favScale;

  @override
  void initState() {
    super.initState();
    // Use the favorites provider as source of truth — the catalog API never
    // returns es_favorito so artwork.esFavorito is always false.
    _esFavorito = ref.read(favoritesProvider).isFavorite(widget.artwork.id);

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
              _esFavorito =
                  ref.read(favoritesProvider).isFavorite(widget.artwork.id);
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
        title: const Text('¿Eliminar esta obra?'),
        content: const Text(
            'Dejará de aparecer en el catálogo. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.nc.tomateA.fill,
              foregroundColor: context.nc.tomateA.onFill,
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
    // La obra trae el slug del artista; se compara con el perfil propio.
    final mySlug =
        role == 'artista' ? ref.watch(profileProvider).profile?.id : null;
    if (role == 'artista' && mySlug == null && !_perfilPedido) {
      _perfilPedido = true;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(profileProvider.notifier).loadMyProfile());
    }
    final canManage = role == 'admin' ||
        (mySlug != null && mySlug.isNotEmpty && mySlug == artwork.artistaSlug);

    final nc = context.nc;
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, artwork, canManage),
            // Hoja con esquinas redondeadas que se monta sobre la imagen.
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.zero,
                child: Container(
                  color: nc.bg,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DetailHeader(artwork: artwork),
                      const SizedBox(height: 22),
                      ArtistTile(artwork: artwork),
                      if (artwork.descripcion.isNotEmpty) ...[
                        const SizedBox(height: 26),
                        DescriptionBlock(text: artwork.descripcion),
                      ],
                      const SizedBox(height: 26),
                      FactsGrid(artwork: artwork),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: DetailActionBar(
            artwork: artwork,
            canManage: canManage,
            isLoggedIn: role != null,
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
    final nc = context.nc;
    return SliverAppBar(
      expandedHeight: _kHeaderHeight,
      pinned: true,
      stretch: true,
      backgroundColor: nc.bg,
      surfaceTintColor: Colors.transparent,
      shape: const Border(),
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: GlassCircleButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      actions: [
        ScaleTransition(
          scale: _favScale,
          child: GlassCircleButton(
            icon: _esFavorito
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: _esFavorito ? nc.magenta : Colors.white,
            tooltip:
                _esFavorito ? 'Quitar de favoritos' : 'Agregar a favoritos',
            onPressed: _toggleFavorito,
          ),
        ),
        const SizedBox(width: 8),
        GlassCircleButton(
          icon: Icons.ios_share_rounded,
          tooltip: 'Compartir',
          onPressed: () => _showShareSheet(context, artwork),
        ),
        if (canManage) ...[
          const SizedBox(width: 8),
          GlassCircleButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Eliminar obra',
            onPressed: () async {
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
                  const SnackBar(content: Text('No se pudo eliminar la obra.')),
                );
              }
            },
          ),
        ],
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            GalleryHeader(
              artwork: artwork,
              imagenActiva: _imagenActiva,
              onTap: () => _openZoom(context),
              onDotTap: (i) => setState(() => _imagenActiva = i),
            ),
            // Borde redondeado de la "hoja" de contenido sobre la imagen.
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              child: Container(
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: nc.bg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: const NcSerpentina(width: 44),
              ),
            ),
          ],
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

  final nc = context.nc;
  final bgCard = nc.bgCard;
  final handleColor = nc.border;
  final titleColor = nc.textPrimary;

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
                color: nc.textSecondary,
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
