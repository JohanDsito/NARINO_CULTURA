import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/artwork_model.dart';

class MyArtworksScreen extends ConsumerStatefulWidget {
  const MyArtworksScreen({super.key});

  @override
  ConsumerState<MyArtworksScreen> createState() => _MyArtworksScreenState();
}

class _MyArtworksScreenState extends ConsumerState<MyArtworksScreen> {
  List<ArtworkModel> _artworks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Obtener slug del perfil — cargar si todavía no está en estado
      String? slug = ref.read(myProfileProvider).profile?.id;
      if (slug == null || slug.isEmpty) {
        await ref.read(myProfileProvider.notifier).loadMyProfile();
        slug = ref.read(myProfileProvider).profile?.id;
      }
      if (slug == null || slug.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'No se pudo cargar tu perfil de artista.';
          });
        }
        return;
      }

      // El backend no filtra por artist_slug, así que paginamos todas las
      // páginas y filtramos localmente por slug del artista actual.
      final myWorks = <ArtworkModel>[];
      String? nextUrl = '/api/v1/artworks/?page_size=100';
      while (nextUrl != null) {
        final response =
            await ApiClient.instance.dio.get(nextUrl);
        final data = response.data;
        if (data is Map) {
          final raw = (data['results'] as List? ?? []);
          myWorks.addAll(
            raw
                .map((e) => ArtworkModel.fromJson(e as Map<String, dynamic>))
                .where((a) => a.artistaSlug == slug),
          );
          nextUrl = data['next'] as String?;
        } else if (data is List) {
          myWorks.addAll(
            (data)
                .map((e) => ArtworkModel.fromJson(e as Map<String, dynamic>))
                .where((a) => a.artistaSlug == slug),
          );
          nextUrl = null;
        } else {
          nextUrl = null;
        }
      }
      final list = myWorks;

      if (mounted) setState(() { _artworks = list; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _error = 'No se pudieron cargar tus obras.'; });
      }
    }
  }

  Future<void> _confirmDelete(ArtworkModel artwork) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar obra'),
        content: Text(
          '¿Eliminar "${artwork.titulo}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _delete(artwork.id);
  }

  Future<void> _delete(String id) async {
    final slug = ref.read(myProfileProvider).profile?.id ?? '';
    // Verificar que la obra pertenece al artista actual antes de eliminar
    final artwork = _artworks.firstWhere(
      (a) => a.id == id,
      orElse: () => _artworks.first,
    );
    if (slug.isNotEmpty && artwork.artistaSlug != slug) return;

    try {
      await ApiClient.instance.dio.delete('/api/v1/artworks/$id/');
      if (!mounted) return;
      setState(() => _artworks.removeWhere((a) => a.id == id));
      ref.read(myProfileProvider.notifier).loadMyProfile();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la obra')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        elevation: 0,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Mis obras',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.oroClaro),
            tooltip: 'Publicar obra',
            onPressed: () async {
              await context.push('/artworks/publish');
              _load();
            },
          ),
        ],
      ),
      body: _buildBody(isDark, textMuted, cs),
    );
  }

  Widget _buildBody(bool isDark, Color textMuted, ColorScheme cs) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: textMuted),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: AppTypography.bodyMedium(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (_artworks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.palette_outlined, size: 56, color: textMuted),
            const SizedBox(height: 14),
            Text(
              'Aún no tienes obras publicadas',
              style: AppTypography.bodyMedium(color: textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await context.push('/artworks/publish');
                _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Publicar primera obra'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '${_artworks.length} ${_artworks.length == 1 ? 'obra' : 'obras'}',
                style: AppTypography.caption(color: textMuted),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _MyArtworkCard(
                  artwork: _artworks[i],
                  onDelete: () => _confirmDelete(_artworks[i]),
                ),
                childCount: _artworks.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de obra propia ───────────────────────────────────────────────────

class _MyArtworkCard extends StatelessWidget {
  const _MyArtworkCard({
    required this.artwork,
    required this.onDelete,
  });

  final ArtworkModel artwork;
  final VoidCallback onDelete;

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
    final bgSubtle =
        isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;

    return GestureDetector(
      onTap: () => context.push('/artworks/${artwork.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen
                  artwork.imagenes.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: artwork.imagenes.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: bgSubtle,
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: bgSubtle,
                            child: Icon(
                              Icons.image_outlined,
                              color: textMuted,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          color: bgSubtle,
                          child: Icon(
                            Icons.palette_outlined,
                            color: textMuted,
                            size: 32,
                          ),
                        ),

                  // Badge de estado
                  if (artwork.estado != 'disponible')
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: artwork.estado == 'en_subasta'
                              ? (isDark
                                  ? AppColors.indigoDark
                                  : AppColors.indigoNoche)
                              : bgSubtle,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          artwork.estado == 'en_subasta'
                              ? 'En subasta'
                              : 'Vendida',
                          style: AppTypography.caption(
                            color: artwork.estado == 'en_subasta'
                                ? Colors.white
                                : textMuted,
                          ),
                        ),
                      ),
                    ),

                  // Botón eliminar
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.88),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info de la obra
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.titulo,
                      style: AppTypography.labelSemiBold(color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artwork.categoria,
                      style: AppTypography.caption(color: textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    artwork.precio != null
                        ? Text(
                            _formatCOP(artwork.precio!),
                            style: AppTypography.labelSemiBold(
                                color: AppColors.oroAndino),
                          )
                        : Text(
                            'Exhibición',
                            style: AppTypography.caption(color: textMuted),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCOP(double value) {
  final raw = value.toStringAsFixed(0);
  return '\$${raw.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  )}';
}
