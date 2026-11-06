import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../artworks/presentation/providers/artwork_provider.dart';
import '../../../artworks/presentation/screens/catalog_screen/artwork_card.dart';
import '../../domain/profile_model.dart';
import '../providers/profile_provider.dart';

/// Perfil público de un artista (acento magenta: artes plásticas).
class ArtistPublicProfileScreen extends ConsumerWidget {
  const ArtistPublicProfileScreen({super.key, required this.artistId});

  /// Slug del artista.
  final String artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    return ref.watch(artistProfileProvider(artistId)).when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Artista')),
            body: ListView(children: [
              NcEmptyState(
                icon: Icons.person_off_outlined,
                accent: nc.tomateA,
                title: 'No pudimos abrir este perfil',
                message: e.toString(),
                actionLabel: 'Reintentar',
                onAction: () => ref.invalidate(artistProfileProvider(artistId)),
              ),
            ]),
          ),
          data: (p) => _Perfil(profile: p),
        );
  }
}

class _Perfil extends ConsumerStatefulWidget {
  const _Perfil({required this.profile});

  final ProfileModel profile;

  @override
  ConsumerState<_Perfil> createState() => _PerfilState();
}

class _PerfilState extends ConsumerState<_Perfil> {
  /// Cambio optimista mientras el servidor responde.
  bool? _override;
  bool _loading = false;

  bool _sigueSegunServidor() {
    // El perfil de artista no trae `is_following`: se deduce de la lista de
    // seguidos (artists/following/).
    final lista = ref.watch(myFollowingProvider).valueOrNull;
    if (lista == null) return widget.profile.esSeguido;
    return lista.any((p) => !p.esMusico && p.id == widget.profile.id);
  }

  Future<void> _alternar(bool sigueAhora) async {
    HapticFeedback.selectionClick();
    setState(() {
      _override = !sigueAhora;
      _loading = true;
    });
    try {
      // El backend usa el mismo POST para seguir y dejar de seguir.
      await ref.read(profileRepositoryProvider).followArtist(widget.profile.id);
      ref.invalidate(myFollowingProvider);
      ref.invalidate(artistProfileProvider(widget.profile.id));
    } catch (_) {
      if (mounted) {
        setState(() => _override = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se pudo actualizar. Intenta de nuevo.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final p = widget.profile;
    final servidor = _sigueSegunServidor();
    final sigue = _override ?? servidor;
    final seguidores = (p.seguidores + (sigue == servidor ? 0 : (sigue ? 1 : -1)))
        .clamp(0, 1 << 30);
    final miSlug = ref.watch(myProfileProvider).profile?.id;
    final esMio = miSlug != null && miSlug == p.id;
    final logueado = ref.watch(currentUserRoleProvider).valueOrNull != null;
    final obras = ref.watch(artistArtworksProvider(p.id));
    final links = p.redesSociales.entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList();
    final foto = p.fotoUrl;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Serpentina del Carnaval, suavizada para no competir
                  // con el contenido.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          for (final c in nc.carnavalGradient.colors)
                            c.withValues(alpha: nc.isDark ? 0.45 : 0.28),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -1,
                    child: Container(
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: nc.bg,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28)),
                      ),
                      child: const NcSerpentina(width: 44),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList.list(children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [
                        ...nc.carnavalGradient.colors,
                        nc.carnavalGradient.colors.first,
                      ]),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: nc.bgCard,
                      backgroundImage: (foto != null && foto.isNotEmpty)
                          ? CachedNetworkImageProvider(foto)
                          : null,
                      child: (foto == null || foto.isEmpty)
                          ? Text(
                              p.nombreArtistico.isNotEmpty
                                  ? p.nombreArtistico.characters.first
                                      .toUpperCase()
                                  : '?',
                              style: AppTypography.displayBold(
                                      color: nc.catalogo.ink)
                                  .copyWith(fontSize: 30))
                          : null,
                    ),
                  ),
                  const Spacer(),
                  if (esMio)
                    NcSecondaryButton(
                      label: 'Editar perfil',
                      icon: Icons.edit_outlined,
                      expand: false,
                      onPressed: () => context.push('/profile/edit'),
                    )
                  else if (logueado)
                    _BotonSeguir(
                      sigue: sigue,
                      loading: _loading,
                      onTap: () => _alternar(sigue),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: p.nombreArtistico),
                  if (p.esVerificado)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(Icons.verified_rounded,
                            size: 22,
                            color: nc.azul,
                            semanticLabel: 'Artista verificada'),
                      ),
                    ),
                ]),
                style: AppTypography.displayBlack(color: nc.textPrimary)
                    .copyWith(fontSize: 28),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (p.disciplina.isNotEmpty)
                    NcStatusPill(
                        label: p.disciplina, accent: nc.catalogo, filled: true),
                  if ((p.ciudad ?? '').isNotEmpty)
                    NcStatusPill(
                        label: p.ciudad!,
                        accent: nc.naranjaA,
                        icon: Icons.place_outlined),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _Dato(valor: '$seguidores', label: 'seguidores'),
                  _Dato(
                      valor: '${obras.valueOrNull?.length ?? p.totalObras}',
                      label: 'obras'),
                  _Dato(
                      valor: '${obras.valueOrNull?.where((a) => a.isDisponible).length ?? p.obrasDisponibles}',
                      label: 'a la venta'),
                ],
              ),
              if ((p.biografia ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Sobre su arte',
                    style: AppTypography.displaySemiBold(color: nc.textPrimary)),
                const SizedBox(height: 8),
                Text(p.biografia!.trim(),
                    style: AppTypography.bodyLarge(color: nc.textSecondary)
                        .copyWith(fontSize: 15)),
              ],
              if (links.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in links)
                      NcPressable(
                        onTap: () => launchUrl(Uri.parse(e.value),
                            mode: LaunchMode.externalApplication),
                        semanticLabel: 'Abrir ${_red(e.key)}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: nc.azulA.tint,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                                color: nc.azul.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_icono(e.key), size: 16, color: nc.azul),
                              const SizedBox(width: 6),
                              Text(_red(e.key),
                                  style: AppTypography.labelMedium(
                                          color: nc.azul)
                                      .copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 26),
              Text('Obras',
                  style: AppTypography.displayBold(color: nc.textPrimary)),
              const SizedBox(height: 12),
              obras.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => NcBanner.error(
                    context, 'No pudimos cargar sus obras.'),
                data: (list) => list.isEmpty
                    ? NcEmptyState(
                        icon: Icons.palette_outlined,
                        accent: nc.catalogo,
                        title: 'Aún no hay obras',
                        message: 'Cuando publique, sus obras aparecerán aquí.',
                        padding: EdgeInsets.zero,
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.64,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) =>
                            CatalogArtworkCard(artwork: list[i]),
                      ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  static IconData _icono(String k) => switch (k) {
        'instagram' => Icons.camera_alt_outlined,
        'facebook' => Icons.facebook_rounded,
        'tiktok' => Icons.music_video_outlined,
        _ => Icons.language_rounded,
      };

  static String _red(String k) => switch (k) {
        'instagram' => 'Instagram',
        'facebook' => 'Facebook',
        'tiktok' => 'TikTok',
        'website' => 'Sitio web',
        _ => k,
      };
}

class _BotonSeguir extends StatelessWidget {
  const _BotonSeguir({
    required this.sigue,
    required this.loading,
    required this.onTap,
  });

  final bool sigue;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = nc.catalogo;
    return Semantics(
      button: true,
      toggled: sigue,
      label: sigue ? 'Dejar de seguir' : 'Seguir',
      excludeSemantics: true,
      child: NcPressable(
        onTap: loading ? null : onTap,
        pressedScale: 0.92,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: sigue ? Colors.transparent : a.fill,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: sigue ? nc.border : a.fill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sigue ? Icons.check_rounded : Icons.add_rounded,
                  size: 18, color: sigue ? nc.textPrimary : a.onFill),
              const SizedBox(width: 4),
              Text(sigue ? 'Siguiendo' : 'Seguir',
                  style: AppTypography.labelMedium(
                          color: sigue ? nc.textPrimary : a.onFill)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.valor, required this.label});

  final String valor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor,
              style: AppTypography.displaySemiBold(color: nc.textPrimary)),
          Text(label, style: AppTypography.bodySmall(color: nc.textSecondary)),
        ],
      ),
    );
  }
}
