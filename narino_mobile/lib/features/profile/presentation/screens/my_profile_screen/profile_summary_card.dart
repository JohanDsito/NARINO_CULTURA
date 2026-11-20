import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/profile_model.dart';
import 'profile_stat.dart';

// ─── Tarjeta principal ──────────────────────────────────────────────────────

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.profile,
    required this.role,
    required this.favs,
    required this.photoVersion,
  });

  final ProfileModel? profile;
  final String? role;
  final int favs;
  final int photoVersion;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final p = profile;
    final nombre = (p?.nombreArtistico.trim().isNotEmpty ?? false)
        ? p!.nombreArtistico
        : 'Tu perfil';
    final foto = p?.fotoUrl;
    final (String rolLabel, NcAccent rolAccent) = switch (role) {
      'artista' => ('Artista', nc.catalogo),
      'gestor' => ('Gestor cultural', nc.eventos),
      'admin' => ('Administración', nc.azulA),
      'comprador' => ('Amante del arte', nc.tienda),
      _ => ('Visitante', nc.azulA),
    };
    final esArtista = role == 'artista';

    return NcCard(
      padding: const EdgeInsets.all(20),
      child: Column(
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
              key: ValueKey('avatar-$photoVersion'),
              radius: 44,
              backgroundColor: nc.bgCard,
              backgroundImage: (foto != null && foto.isNotEmpty)
                  // La key fuerza a redibujar tras cambiar la foto; no se
                  // altera la URL (podría ser firmada).
                  ? CachedNetworkImageProvider(foto)
                  : null,
              child: (foto == null || foto.isEmpty)
                  ? Text(
                      nombre.characters.first.toUpperCase(),
                      style: AppTypography.displayBold(color: rolAccent.ink)
                          .copyWith(fontSize: 34),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(nombre,
                    textAlign: TextAlign.center,
                    style: AppTypography.displayBold(color: nc.textPrimary)),
              ),
              if (p?.esVerificado == true) ...[
                const SizedBox(width: 6),
                Icon(Icons.verified_rounded, size: 20, color: nc.azul),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              NcStatusPill(label: rolLabel, accent: rolAccent, filled: true),
              if (p?.disciplina.trim().isNotEmpty == true)
                NcStatusPill(label: p!.disciplina, accent: rolAccent),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              ProfileStat(
                valor: '${p?.seguidores ?? 0}',
                label: 'Seguidores',
              ),
              ProfileStat(
                valor: '${p?.totalObras ?? 0}',
                label: 'Obras',
                onTap: esArtista
                    ? () => context.push('/profile/my-artworks')
                    : null,
              ),
              ProfileStat(
                valor: '$favs',
                label: 'Favoritos',
                onTap: () => context.push('/marketplace/favorites'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: NcSecondaryButton(
                  label: 'Editar perfil',
                  icon: Icons.edit_outlined,
                  onPressed: () => context.push('/profile/edit'),
                ),
              ),
              if (esArtista && (p?.id.isNotEmpty ?? false)) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: NcSecondaryButton(
                    label: 'Ver público',
                    icon: Icons.visibility_outlined,
                    onPressed: () => context.push('/artistas/${p!.id}'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
