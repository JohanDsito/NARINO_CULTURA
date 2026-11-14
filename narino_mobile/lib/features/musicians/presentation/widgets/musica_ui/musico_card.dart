import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/musician_model.dart';
import '../../providers/musician_provider.dart';
import 'estrellas.dart';
import 'musico_avatar.dart';
import 'seguir_button.dart';
import '../../../domain/agrupaciones.dart';

/// Seguidores con el ajuste optimista de [seguidosProvider].
int seguidoresVisibles(MusicianModel m, SeguidosState s) =>
    (m.followersCount + s.delta(m.slug, servidorDiceQueSigue: m.isFollowing))
        .clamp(0, 1 << 30);

/// Tarjeta de músico para listas (directorio y descubrimiento).
class MusicoCard extends ConsumerWidget {
  const MusicoCard({super.key, required this.musician});

  final MusicianModel musician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final m = musician;
    final seguidores = seguidoresVisibles(m, ref.watch(seguidosProvider));
    final detalle = [
      if (formatoAgrupacion(m.aggregationType).isNotEmpty)
        formatoAgrupacion(m.aggregationType),
      if ((m.city ?? '').isNotEmpty) m.city!,
    ].join(' · ');

    return NcCard(
      padding: const EdgeInsets.all(14),
      gradientBorder: false,
      onTap: () => context.push('/musicians/${m.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MusicoAvatar(musician: m, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(m.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSemiBold(
                                      color: nc.textPrimary)
                                  .copyWith(fontSize: 16)),
                        ),
                        if (m.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified_rounded,
                              size: 16, color: nc.musica.ink),
                        ],
                      ],
                    ),
                    if (detalle.isNotEmpty)
                      Text(detalle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTypography.bodySmall(color: nc.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SeguirButton(musician: m, compact: true),
            ],
          ),
          if (m.genres.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in m.genres.take(3))
                  NcStatusPill(label: g, accent: nc.musica),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people_outline_rounded,
                  size: 16, color: nc.textSecondary),
              const SizedBox(width: 4),
              Text('$seguidores seguidores',
                  style: AppTypography.bodySmall(color: nc.textSecondary)),
              if (m.reviewsCount > 0) ...[
                const SizedBox(width: 14),
                Estrellas(valor: m.averageRating, size: 14),
                const SizedBox(width: 4),
                Text('(${m.reviewsCount})',
                    style: AppTypography.bodySmall(color: nc.textSecondary)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
