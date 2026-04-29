import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/artwork_model.dart';
import '../providers/artwork_provider.dart';

class ArtworkDetailScreen extends ConsumerWidget {
  const ArtworkDetailScreen({super.key, required this.artworkId});

  final int artworkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncArtwork = ref.watch(artworkDetailProvider(artworkId));

    return asyncArtwork.when(
      data: (artwork) => Scaffold(
        backgroundColor: AppColors.bgLight,
        body: _ArtworkDetailBody(artwork: artwork),
      ),
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bgLight,
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
            padding: const EdgeInsets.all(16),
            child: Text(
              e.toString(),
              style:
                  AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtworkDetailBody extends ConsumerStatefulWidget {
  const _ArtworkDetailBody({required this.artwork});

  final ArtworkModel artwork;

  @override
  ConsumerState<_ArtworkDetailBody> createState() => _ArtworkDetailBodyState();
}

class _ArtworkDetailBodyState extends ConsumerState<_ArtworkDetailBody> {
  int _imagenActiva = 0;
  late bool _esFavorito;
  late int _cantidadFavoritos;

  @override
  void initState() {
    super.initState();
    _esFavorito = widget.artwork.esFavorito;
    _cantidadFavoritos = widget.artwork.cantidadFavoritos;
  }

  void _toggleFavorito() {
    setState(() {
      _esFavorito = !_esFavorito;
      _cantidadFavoritos = (_cantidadFavoritos + (_esFavorito ? 1 : -1)).clamp(
        0,
        1 << 30,
      );
    });
    ref.read(artworkProvider.notifier).toggleFavorite(widget.artwork.id);
  }

  void _compartir(BuildContext context) {
    _showShareSheet(context, widget.artwork);
  }

  Future<void> _openZoom(BuildContext context) async {
    final images = widget.artwork.imagenes;
    if (images.isEmpty) return;

    final controller = PageController(initialPage: _imagenActiva);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              '${_imagenActiva + 1}/${images.length}',
              style: AppTypography.labelSemiBold(color: Colors.white),
            ),
          ),
          body: PhotoViewGallery.builder(
            pageController: controller,
            itemCount: images.length,
            builder: (context, index) {
              final url = images[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(url),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3.0,
              );
            },
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            onPageChanged: (i) => setState(() => _imagenActiva = i),
            loadingBuilder: (context, event) => const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;
    final imagenes = artwork.imagenes;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.obsidiana,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(
                _esFavorito ? Icons.favorite : Icons.favorite_outline,
                color: _esFavorito ? Colors.red : Colors.white,
              ),
              onPressed: _toggleFavorito,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _compartir(context),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'edit') {
                  context.push('/artworks/${artwork.id}/edit');
                }
                if (value == 'delete') {
                  final ok = await _confirmDelete(context);
                  if (!ok) return;
                  final deleted =
                      await ref.read(artworkProvider.notifier).deleteArtwork(
                            artwork.id,
                          );
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
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => _openZoom(context),
                  child: imagenes.isNotEmpty
                      ? Image.network(
                          imagenes[_imagenActiva],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.bgSubtleLight,
                            child: const Icon(
                              Icons.image_outlined,
                              size: 60,
                              color: AppColors.borderLight,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.bgSubtleLight,
                          child: const Icon(
                            Icons.palette_outlined,
                            size: 60,
                            color: AppColors.borderLight,
                          ),
                        ),
                ),
                if (imagenes.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        imagenes.length,
                        (i) => GestureDetector(
                          onTap: () => setState(() => _imagenActiva = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _imagenActiva == i ? 20 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: _imagenActiva == i
                                  ? AppColors.oroClaro
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tierraPalida,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        artwork.categoria,
                        style: AppTypography.caption(
                          color: AppColors.tierraProfunda,
                        ),
                      ),
                    ),
                    if (artwork.estado != 'disponible') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: artwork.estado == 'en_subasta'
                              ? AppColors.indigoPalido
                              : AppColors.bgSubtleLight,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          artwork.estado == 'en_subasta'
                              ? 'En subasta'
                              : 'Vendida',
                          style: AppTypography.caption(
                            color: artwork.estado == 'en_subasta'
                                ? AppColors.indigoNoche
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          _esFavorito ? Icons.favorite : Icons.favorite_outline,
                          color: _esFavorito
                              ? Colors.red
                              : AppColors.textMutedLight,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_cantidadFavoritos',
                          style: AppTypography.caption(
                            color: AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  artwork.titulo,
                  style: AppTypography.displaySemiBold(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                artwork.precio != null
                    ? Text(
                        '${_formatCOP(artwork.precio!)} COP',
                        style: AppTypography.labelSemiBold(
                          color: AppColors.oroAndino,
                        ),
                      )
                    : Text(
                        'Obra para exhibición — sin precio',
                        style: AppTypography.bodyMedium(
                          color: AppColors.textMutedLight,
                        ),
                      ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 12),
                Text(
                  'Ficha técnica',
                  style: AppTypography.labelSemiBold(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                _InfoRow('Categoría', artwork.categoria),
                if (artwork.tecnica != null)
                  _InfoRow('Técnica', artwork.tecnica!),
                if (artwork.dimensiones != null)
                  _InfoRow('Dimensiones', artwork.dimensiones!),
                if (artwork.anio != null)
                  _InfoRow('Año', artwork.anio.toString()),
                const SizedBox(height: 20),
                if (artwork.descripcion.isNotEmpty) ...[
                  Text(
                    'Descripción',
                    style: AppTypography.labelSemiBold(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artwork.descripcion,
                    style: AppTypography.bodyMedium(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 12),
                Text(
                  'Artista',
                  style: AppTypography.labelSemiBold(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.tierraPalida,
                        backgroundImage: artwork.artistaFoto != null
                            ? NetworkImage(artwork.artistaFoto!)
                            : null,
                        child: artwork.artistaFoto == null
                            ? Text(
                                artwork.artistaNombre.isNotEmpty
                                    ? artwork.artistaNombre[0].toUpperCase()
                                    : '?',
                                style: AppTypography.displaySemiBold(
                                  color: AppColors.tierraProfunda,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artwork.artistaNombre,
                              style: AppTypography.labelSemiBold(
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            Text(
                              'Ver perfil completo',
                              style: AppTypography.caption(
                                color: AppColors.tierraProfunda,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textMutedLight,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (artwork.estado == 'disponible' && artwork.precio != null)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Carrito disponible próximamente'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: Text(
                        'Agregar al carrito',
                        style: AppTypography.labelSemiBold(color: Colors.white),
                      ),
                    ),
                  ),
                if (artwork.estado == 'en_subasta') ...[
                  const SizedBox(height: 16),
                  const _AuctionBanner(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatCOP(double value) {
    final raw = value.toStringAsFixed(0);
    final formatted = raw.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '\$$formatted';
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );
    return result ?? false;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.caption(color: AppColors.textMutedLight),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall(color: AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuctionBanner extends StatelessWidget {
  const _AuctionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.indigoPalido,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel_outlined, color: AppColors.indigoNoche),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esta obra está en subasta. Revisa el estado de la puja en el módulo de Subastas.',
              style: AppTypography.bodySmall(color: AppColors.indigoNoche),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showShareSheet(BuildContext context, ArtworkModel artwork) async {
  final url = 'https://narinocultura.app/artworks/${artwork.id}';
  final texto =
      '🎨 ${artwork.titulo} — por ${artwork.artistaNombre}\n\nDescubre esta obra en Nariño Cultura:\n$url';

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgCardLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Compartir obra',
            style: AppTypography.displaySemiBold(
                color: AppColors.textPrimaryLight),
          ),
          const SizedBox(height: 20),
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
                color: AppColors.textMutedLight,
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
              minimumSize: const Size(double.infinity, 44),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 31),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.caption(color: AppColors.textMutedLight),
          ),
        ],
      ),
    );
  }
}

Future<void> _shareToWhatsApp(String texto) async {
  final encoded = Uri.encodeComponent(texto);
  final schemeUri = Uri.parse('whatsapp://send?text=$encoded');
  final okScheme =
      await launchUrl(schemeUri, mode: LaunchMode.externalApplication);
  if (okScheme) return;

  final webUri = Uri.parse('https://wa.me/?text=$encoded');
  final okWeb = await launchUrl(webUri, mode: LaunchMode.externalApplication);
  if (!okWeb) await Share.share(texto);
}

Future<void> _shareToFacebook(String url) async {
  final encoded = Uri.encodeComponent(url);
  final uri =
      Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$encoded');
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) await Share.share(url);
}

Future<void> _shareToX(String url, String texto) async {
  final encodedText = Uri.encodeComponent(texto);
  final uri = Uri.parse('https://twitter.com/intent/tweet?text=$encodedText');
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) await Share.share('$texto\n$url');
}
