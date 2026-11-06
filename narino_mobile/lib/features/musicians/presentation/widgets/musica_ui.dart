import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/musician_model.dart';
import '../providers/musician_provider.dart';

String formatoAgrupacion(String? t) => switch (t?.toUpperCase()) {
      'SOLISTA' => 'Solista',
      'DUO' => 'Dúo',
      'TRIO' => 'Trío',
      'BANDA' => 'Banda',
      'COLECTIVO' => 'Colectivo',
      'DJ' => 'DJ',
      _ => '',
    };

/// Avatar con anillo: serpentina si el perfil está verificado, azul si no.
class MusicoAvatar extends StatelessWidget {
  const MusicoAvatar({super.key, required this.musician, this.radius = 28});

  final MusicianModel musician;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final inicial = musician.name.isNotEmpty
        ? musician.name.characters.first.toUpperCase()
        : '♪';
    final foto = musician.photoUrl;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: musician.isVerified
            ? SweepGradient(colors: [
                ...nc.carnavalGradient.colors,
                nc.carnavalGradient.colors.first,
              ])
            : null,
        color: musician.isVerified ? null : nc.musica.fill,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: nc.bgCard,
        backgroundImage: (foto != null && foto.isNotEmpty)
            ? CachedNetworkImageProvider(foto)
            : null,
        child: (foto == null || foto.isEmpty)
            ? Text(inicial,
                style: AppTypography.displaySemiBold(color: nc.musica.ink)
                    .copyWith(fontSize: radius * 0.8))
            : null,
      ),
    );
  }
}

/// Botón Seguir / Siguiendo conectado a [seguidosProvider].
class SeguirButton extends ConsumerWidget {
  const SeguirButton({super.key, required this.musician, this.compact = false});

  final MusicianModel musician;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final logueado = ref.watch(currentUserRoleProvider).valueOrNull != null;
    if (!logueado) return const SizedBox.shrink();
    // La lista de `musicians/following/` es la fuente de verdad.
    final sigue = ref.watch(seguidosProvider).sigue(musician.slug);

    return Semantics(
      button: true,
      toggled: sigue,
      label: sigue ? 'Dejar de seguir a ${musician.name}' : 'Seguir a ${musician.name}',
      excludeSemantics: true,
      child: NcPressable(
        onTap: () async {
          HapticFeedback.selectionClick();
          final ok =
              await ref.read(seguidosProvider.notifier).alternar(musician.slug);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('No se pudo actualizar. Intenta de nuevo.')));
          }
        },
        pressedScale: 0.92,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 20, vertical: compact ? 8 : 12),
          decoration: BoxDecoration(
            color: sigue ? Colors.transparent : nc.musica.fill,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: sigue ? nc.border : nc.musica.fill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sigue ? Icons.check_rounded : Icons.add_rounded,
                  size: compact ? 16 : 18,
                  color: sigue ? nc.textPrimary : nc.musica.onFill),
              const SizedBox(width: 4),
              Text(sigue ? 'Siguiendo' : 'Seguir',
                  style: AppTypography.labelMedium(
                          color: sigue ? nc.textPrimary : nc.musica.onFill)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seguidores con el ajuste optimista de [seguidosProvider].
int seguidoresVisibles(MusicianModel m, SeguidosState s) =>
    (m.followersCount + s.delta(m.slug, servidorDiceQueSigue: m.isFollowing))
        .clamp(0, 1 << 30);

/// Estrellas de 0 a 5 (con media estrella).
class Estrellas extends StatelessWidget {
  const Estrellas({super.key, required this.valor, this.size = 16});

  final double valor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Semantics(
      label: '${valor.toStringAsFixed(1)} de 5 estrellas',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              valor >= i
                  ? Icons.star_rounded
                  : (valor >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
              size: size,
              color: nc.oro,
            ),
        ],
      ),
    );
  }
}

/// Fondo de portada (para obras sin miniatura).
class PortadaMusical extends StatelessWidget {
  const PortadaMusical({super.key, this.url, this.icon = Icons.music_note_rounded});

  final String? url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nc.musica.tint, nc.magentaA.tint],
        ),
      ),
      child: Center(child: Icon(icon, color: nc.musica.ink, size: 28)),
    );
    if (url == null || url!.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

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
                          style: AppTypography.bodySmall(
                              color: nc.textSecondary)),
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
