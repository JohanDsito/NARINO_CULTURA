import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/artwork_model.dart';
import '../providers/artwork_provider.dart';
import '../../../../shared/widgets/dialogs/confirmar_accion.dart';
import 'my_artworks_screen/mis_obras_filtros.dart';
import 'my_artworks_screen/mis_obras_mensaje.dart';
import 'my_artworks_screen/my_artwork_card.dart';

/// Panel de obras del artista: resumen por estado, filtro y acciones propias.
class MyArtworksScreen extends ConsumerStatefulWidget {
  const MyArtworksScreen({super.key});

  @override
  ConsumerState<MyArtworksScreen> createState() => _MyArtworksScreenState();
}

class _MyArtworksScreenState extends ConsumerState<MyArtworksScreen> {
  List<ArtworkModel> _artworks = [];
  bool _isLoading = true;
  String? _error;

  /// `null` = todas.
  String? _filtro;

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
      String? slug = ref.read(myProfileProvider).profile?.id;
      if (slug == null || slug.isEmpty) {
        await ref.read(myProfileProvider.notifier).loadMyProfile();
        slug = ref.read(myProfileProvider).profile?.id;
      }
      if (slug == null || slug.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'No encontramos tu perfil de artista. Complétalo desde '
                'tu perfil para publicar obras.';
          });
        }
        return;
      }
      final list = await ref.read(artworkRepositoryProvider).getByArtist(slug);
      list.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      if (mounted) {
        setState(() {
          _artworks = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'No se pudieron cargar tus obras.';
        });
      }
    }
  }

  Future<void> _publicar() async {
    await context.push('/artworks/publish');
    if (mounted) _load();
  }

  Future<void> _confirmDelete(ArtworkModel artwork) async {
    final ok = await confirmarAccion(
      context,
      titulo: '¿Eliminar esta obra?',
      mensaje: '"${artwork.titulo}" dejará de aparecer en el catálogo. Esta '
          'acción no se puede deshacer.',
      confirmar: 'Eliminar',
      peligro: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(artworkRepositoryProvider).delete(artwork.id);
      if (!mounted) return;
      setState(() => _artworks.removeWhere((a) => a.id == artwork.id));
      ref.read(myProfileProvider.notifier).loadMyProfile();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Obra eliminada')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la obra.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis obras'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: NcIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Publicar obra',
              onPressed: _publicar,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    final nc = context.nc;
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return MisObrasMensaje(
        icon: Icons.cloud_off_rounded,
        accent: nc.tomateA,
        title: 'Algo salió mal',
        text: _error!,
        action: 'Reintentar',
        onAction: _load,
      );
    }
    if (_artworks.isEmpty) {
      return MisObrasMensaje(
        icon: Icons.palette_outlined,
        accent: nc.catalogo,
        title: 'Tu galería está esperando',
        text: 'Publica tu primera obra y empieza a compartir tu arte con todo '
            'Nariño.',
        action: 'Publicar mi primera obra',
        onAction: _publicar,
      );
    }

    final visibles = _filtro == null
        ? _artworks
        : _artworks.where((a) => a.estado == _filtro).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: MisObrasFiltros(
            obras: _artworks,
            filtro: _filtro,
            onFiltro: (f) => setState(() => _filtro = f),
          ),
        ),
        if (visibles.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No tienes obras en este estado.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(color: nc.textSecondary)),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverGrid(
              gridDelegate: ncArtworkGridDelegate,
              delegate: SliverChildBuilderDelegate(
                (_, i) => MyArtworkCard(
                  artwork: visibles[i],
                  onEdit: () async {
                    await context.push('/artworks/${visibles[i].id}/edit');
                    if (mounted) _load();
                  },
                  onAuction: () async {
                    await context.push('/auctions/new');
                    if (mounted) _load();
                  },
                  onDelete: () => _confirmDelete(visibles[i]),
                ),
                childCount: visibles.length,
              ),
            ),
          ),
      ],
    );
  }
}
