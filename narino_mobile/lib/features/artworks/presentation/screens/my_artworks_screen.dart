import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/artwork_model.dart';
import '../providers/artwork_provider.dart';
import 'my_artworks_screen/my_artwork_card.dart';

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

      final list = await ref.read(artworkRepositoryProvider).getByArtist(slug);

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
      await ref.read(artworkRepositoryProvider).delete(id);
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
                (context, i) => MyArtworkCard(
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

