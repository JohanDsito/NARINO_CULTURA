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
      data: (artwork) => _DetailScaffold(artwork: artwork),
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

class _DetailScaffold extends ConsumerWidget {
  const _DetailScaffold({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(artworkProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          artwork.titulo,
          style: AppTypography.labelSemiBold(color: AppColors.oroClaro),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _showShareSheet(context, artwork),
          ),
          IconButton(
            icon: Icon(
              artwork.esFavorito ? Icons.favorite : Icons.favorite_border,
              color: artwork.esFavorito ? AppColors.error : AppColors.oroClaro,
            ),
            onPressed: () async {
              await notifier.toggleFavorite(artwork.id);
              ref.invalidate(artworkDetailProvider(artwork.id));
            },
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
                final deleted = await notifier.deleteArtwork(artwork.id);
                if (context.mounted) {
                  if (deleted) {
                    context.pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('No se pudo eliminar la obra.')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _Gallery(images: artwork.imagenes),
          const SizedBox(height: 14),
          _Header(artwork: artwork),
          const SizedBox(height: 14),
          _InfoGrid(artwork: artwork),
          const SizedBox(height: 14),
          _Description(text: artwork.descripcion),
          const SizedBox(height: 14),
          _ArtistCard(artwork: artwork),
          const SizedBox(height: 14),
          if (artwork.estado == 'en_subasta') const _AuctionBanner(),
        ],
      ),
    );
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

class _Gallery extends StatelessWidget {
  const _Gallery({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 280,
          color: AppColors.bgSubtleLight,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_outlined,
            size: 44,
            color: AppColors.textMutedLight,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 320,
        child: PhotoViewGallery.builder(
          itemCount: images.length,
          builder: (context, index) {
            final url = images[index];
            return PhotoViewGalleryPageOptions(
              imageProvider: CachedNetworkImageProvider(url),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3.0,
              heroAttributes: PhotoViewHeroAttributes(tag: 'artwork-$url'),
            );
          },
          backgroundDecoration: const BoxDecoration(color: AppColors.bgLight),
          scrollPhysics: const BouncingScrollPhysics(),
          loadingBuilder: (context, event) => const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            artwork.titulo,
            style: AppTypography.displaySemiBold(
                color: AppColors.textPrimaryLight),
          ),
          const SizedBox(height: 6),
          Text(
            artwork.artistaNombre,
            style:
                AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(text: artwork.categoria),
              _Pill(text: _estadoLabel(artwork.estado)),
              _Pill(text: '${artwork.cantidadFavoritos} favoritos'),
              if (artwork.precio != null) _Pill(text: '\$${artwork.precio}'),
            ],
          ),
        ],
      ),
    );
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case 'vendida':
        return 'Vendida';
      case 'en_subasta':
        return 'En subasta';
      default:
        return 'Disponible';
    }
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String value})>[
      (label: 'Técnica', value: artwork.tecnica ?? '—'),
      (label: 'Dimensiones', value: artwork.dimensiones ?? '—'),
      (label: 'Año', value: artwork.anio?.toString() ?? '—'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información',
            style:
                AppTypography.labelSemiBold(color: AppColors.textPrimaryLight),
          ),
          const SizedBox(height: 12),
          for (final item in items) ...[
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    item.label,
                    style: AppTypography.bodySmall(
                      color: AppColors.textMutedLight,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.value,
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descripción',
            style:
                AppTypography.labelSemiBold(color: AppColors.textPrimaryLight),
          ),
          const SizedBox(height: 10),
          Text(
            text.isEmpty ? 'Sin descripción.' : text,
            style:
                AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
          ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 52,
              height: 52,
              color: AppColors.bgSubtleLight,
              child: artwork.artistaFoto == null || artwork.artistaFoto!.isEmpty
                  ? const Icon(Icons.person_outline,
                      color: AppColors.textMutedLight)
                  : CachedNetworkImage(
                      imageUrl: artwork.artistaFoto!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.person_outline,
                        color: AppColors.textMutedLight,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Artista',
                  style: AppTypography.caption(color: AppColors.textMutedLight),
                ),
                const SizedBox(height: 2),
                Text(
                  artwork.artistaNombre,
                  style: AppTypography.labelSemiBold(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go('/profile'),
            child: Text(
              'Ver perfil',
              style: AppTypography.labelSemiBold(color: AppColors.indigoNoche),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.oroPalido,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTypography.caption(color: AppColors.obsidiana),
      ),
    );
  }
}

Future<void> _showShareSheet(BuildContext context, ArtworkModel artwork) async {
  final url = 'https://narino-cultura.app/artworks/${artwork.id}';
  final text = '${artwork.titulo} · ${artwork.artistaNombre}\n$url';

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compartir',
                style: AppTypography.displaySemiBold(
                    color: AppColors.textPrimaryLight),
              ),
              const SizedBox(height: 12),
              _ShareTile(
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                onTap: () => _shareToWhatsApp(text),
              ),
              _ShareTile(
                icon: Icons.public,
                label: 'Facebook',
                onTap: () => _shareToFacebook(url),
              ),
              _ShareTile(
                icon: Icons.alternate_email,
                label: 'X / Twitter',
                onTap: () => _shareToX(url, artwork.titulo),
              ),
              _ShareTile(
                icon: Icons.copy,
                label: 'Copiar enlace',
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                },
              ),
              _ShareTile(
                icon: Icons.more_horiz,
                label: 'Más opciones',
                onTap: () => Share.share(text),
              ),
              const SizedBox(height: 6),
              Text(
                url,
                style: AppTypography.bodySmall(color: AppColors.textMutedLight),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () async {
        Navigator.of(context).pop();
        await onTap();
      },
      leading: Icon(icon, color: AppColors.indigoNoche),
      title: Text(
        label,
        style: AppTypography.labelSemiBold(color: AppColors.textPrimaryLight),
      ),
    );
  }
}

Future<void> _shareToWhatsApp(String text) async {
  final encoded = Uri.encodeComponent(text);
  final uri = Uri.parse('https://wa.me/?text=$encoded');
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) await Share.share(text);
}

Future<void> _shareToFacebook(String url) async {
  final encoded = Uri.encodeComponent(url);
  final uri =
      Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$encoded');
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) await Share.share(url);
}

Future<void> _shareToX(String url, String title) async {
  final encodedUrl = Uri.encodeComponent(url);
  final encodedText = Uri.encodeComponent(title);
  final uri = Uri.parse(
      'https://twitter.com/intent/tweet?text=$encodedText&url=$encodedUrl');
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) await Share.share('$title\n$url');
}
