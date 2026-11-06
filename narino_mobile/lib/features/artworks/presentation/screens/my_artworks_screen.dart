import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/artwork_model.dart';
import '../providers/artwork_provider.dart';
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar esta obra?'),
        content: Text(
            '"${artwork.titulo}" dejará de aparecer en el catálogo. Esta acción '
            'no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tomate,
              foregroundColor: Colors.black,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
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

    Widget mensaje({
      required IconData icon,
      required NcAccent accent,
      required String title,
      required String text,
      required String action,
      required VoidCallback onAction,
    }) =>
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 40),
            NcCard(
              child: Column(
                children: [
                  NcAccentIcon(icon: icon, accent: accent, size: 64, glow: true),
                  const SizedBox(height: 16),
                  Text(title,
                      textAlign: TextAlign.center,
                      style:
                          AppTypography.displaySemiBold(color: nc.textPrimary)),
                  const SizedBox(height: 8),
                  Text(text,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium(color: nc.textSecondary)),
                  const SizedBox(height: 20),
                  NcPrimaryButton(label: action, onPressed: onAction),
                ],
              ),
            ),
          ],
        );

    if (_error != null) {
      return mensaje(
        icon: Icons.cloud_off_rounded,
        accent: nc.tomateA,
        title: 'Algo salió mal',
        text: _error!,
        action: 'Reintentar',
        onAction: _load,
      );
    }
    if (_artworks.isEmpty) {
      return mensaje(
        icon: Icons.palette_outlined,
        accent: nc.catalogo,
        title: 'Tu galería está esperando',
        text: 'Publica tu primera obra y empieza a compartir tu arte con todo '
            'Nariño.',
        action: 'Publicar mi primera obra',
        onAction: _publicar,
      );
    }

    int contar(String e) => _artworks.where((a) => a.estado == e).length;
    final stats = <(String?, String, int, NcAccent)>[
      (null, 'Todas', _artworks.length, nc.catalogo),
      ('disponible', 'Disponibles', contar('disponible'), nc.successA),
      ('en_subasta', 'En subasta', contar('en_subasta'), nc.subastas),
      ('vendida', 'Vendidas', contar('vendida'), nc.tomateA),
    ];
    final visibles = _filtro == null
        ? _artworks
        : _artworks.where((a) => a.estado == _filtro).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: stats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final s = stats[i];
                final sel = _filtro == s.$1;
                return Semantics(
                  selected: sel,
                  button: true,
                  label: '${s.$2}: ${s.$3}',
                  excludeSemantics: true,
                  child: NcPressable(
                    onTap: () => setState(() => _filtro = s.$1),
                    pressedScale: 0.95,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 108,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sel ? s.$4.fill : nc.bgCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: sel ? s.$4.fill : nc.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${s.$3}',
                              style: AppTypography.displayBold(
                                  color: sel ? s.$4.onFill : s.$4.ink)),
                          Text(s.$2,
                              style: AppTypography.bodySmall(
                                  color: sel
                                      ? s.$4.onFill
                                      : nc.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: 0.64,
              ),
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
