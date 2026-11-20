import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/artwork_model.dart';

/// Artista con anillo de serpentina y acceso a su perfil.
class ArtistTile extends StatelessWidget {
  const ArtistTile({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final inicial = artwork.artistaNombre.isNotEmpty
        ? artwork.artistaNombre.characters.first.toUpperCase()
        : '?';
    final foto = artwork.artistaFoto;
    return NcCard(
      padding: const EdgeInsets.all(14),
      onTap: artwork.artistaSlug.isEmpty
          ? null
          : () => context.push('/artistas/${artwork.artistaSlug}'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                ...nc.carnavalGradient.colors,
                nc.carnavalGradient.colors.first,
              ]),
            ),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: nc.bgCard,
              backgroundImage: (foto != null && foto.isNotEmpty)
                  ? CachedNetworkImageProvider(foto)
                  : null,
              child: (foto == null || foto.isEmpty)
                  ? Text(inicial,
                      style:
                          AppTypography.displaySemiBold(color: nc.catalogo.ink))
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CREADA POR',
                    style: AppTypography.caption(color: nc.textMuted)
                        .copyWith(letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text(
                  artwork.artistaNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSemiBold(color: nc.textPrimary)
                      .copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          if (artwork.artistaSlug.isNotEmpty) ...[
            Text('Ver perfil',
                style: AppTypography.labelMedium(color: nc.azul)
                    .copyWith(fontWeight: FontWeight.w600)),
            Icon(Icons.chevron_right_rounded, color: nc.azul),
          ],
        ],
      ),
    );
  }
}
