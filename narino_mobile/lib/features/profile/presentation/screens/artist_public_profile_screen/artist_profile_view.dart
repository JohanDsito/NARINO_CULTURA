import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/providers/user_role_provider.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../artworks/presentation/providers/artwork_provider.dart';
import '../../../domain/profile_model.dart';
import '../../providers/profile_provider.dart';
import 'artist_artworks_grid.dart';
import 'artist_avatar.dart';
import 'artist_links_wrap.dart';
import 'artist_profile_app_bar.dart';
import 'artist_stat.dart';
import 'follow_artist_button.dart';

/// Perfil público de un artista: datos, seguir, redes y sus obras.
class ArtistProfileView extends ConsumerStatefulWidget {
  const ArtistProfileView({super.key, required this.profile});

  final ProfileModel profile;

  @override
  ConsumerState<ArtistProfileView> createState() => _ArtistProfileViewState();
}

class _ArtistProfileViewState extends ConsumerState<ArtistProfileView> {
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
    final seguidores =
        (p.seguidores + (sigue == servidor ? 0 : (sigue ? 1 : -1)))
            .clamp(0, 1 << 30);
    final miSlug = ref.watch(myProfileProvider).profile?.id;
    final esMio = miSlug != null && miSlug == p.id;
    final logueado = ref.watch(currentUserRoleProvider).valueOrNull != null;
    final obras = ref.watch(artistArtworksProvider(p.id));
    final links = p.redesSociales.entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const ArtistProfileAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList.list(children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ArtistAvatar(nombre: p.nombreArtistico, fotoUrl: p.fotoUrl),
                  const Spacer(),
                  if (esMio)
                    NcSecondaryButton(
                      label: 'Editar perfil',
                      icon: Icons.edit_outlined,
                      expand: false,
                      onPressed: () => context.push('/profile/edit'),
                    )
                  else if (logueado)
                    FollowArtistButton(
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
                  ArtistStat(valor: '$seguidores', label: 'seguidores'),
                  ArtistStat(
                      valor: '${obras.valueOrNull?.length ?? p.totalObras}',
                      label: 'obras'),
                  ArtistStat(
                      valor:
                          '${obras.valueOrNull?.where((a) => a.isDisponible).length ?? p.obrasDisponibles}',
                      label: 'a la venta'),
                ],
              ),
              if ((p.biografia ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Sobre su arte',
                    style:
                        AppTypography.displaySemiBold(color: nc.textPrimary)),
                const SizedBox(height: 8),
                Text(p.biografia!.trim(),
                    style: AppTypography.bodyLarge(color: nc.textSecondary)
                        .copyWith(fontSize: 15)),
              ],
              if (links.isNotEmpty) ...[
                const SizedBox(height: 18),
                ArtistLinksWrap(links: links),
              ],
              const SizedBox(height: 26),
              Text('Obras',
                  style: AppTypography.displayBold(color: nc.textPrimary)),
              const SizedBox(height: 12),
              ArtistArtworksGrid(obras: obras),
            ]),
          ),
        ],
      ),
    );
  }
}
