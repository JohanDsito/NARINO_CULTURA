import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/profile_model.dart';
import '../../widgets/disciplinas.dart';

class FollowingTile extends StatelessWidget {
  const FollowingTile({super.key, required this.perfil});

  final ProfileModel perfil;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final p = perfil;
    final d = disciplinaDe(p.disciplina);
    final accent = p.esMusico ? nc.musica : (d?.accent(nc) ?? nc.catalogo);
    final sub = p.esMusico
        ? 'Música'
        : (d?.label ?? (p.disciplina.isNotEmpty ? p.disciplina : 'Artista'));
    final foto = p.fotoUrl;
    final inicial = p.nombreArtistico.isNotEmpty
        ? p.nombreArtistico.characters.first.toUpperCase()
        : '?';

    return Semantics(
      button: true,
      label: '${p.nombreArtistico}, $sub',
      excludeSemantics: true,
      child: NcPressable(
        onTap: () => context
            .push(p.esMusico ? '/musicians/${p.id}' : '/artistas/${p.id}'),
        pressedScale: 0.98,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: nc.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: nc.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.fill, width: 2),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: accent.tint,
                  backgroundImage: (foto != null && foto.isNotEmpty)
                      ? CachedNetworkImageProvider(foto)
                      : null,
                  child: (foto == null || foto.isEmpty)
                      ? Text(inicial,
                          style:
                              AppTypography.displaySemiBold(color: accent.ink))
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(p.nombreArtistico,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSemiBold(
                                  color: nc.textPrimary)),
                        ),
                        if (p.esVerificado) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified_rounded,
                              size: 16, color: nc.azul),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                            p.esMusico
                                ? Icons.music_note_rounded
                                : (d?.icon ?? Icons.palette_outlined),
                            size: 14,
                            color: accent.ink),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  AppTypography.bodySmall(color: accent.ink)),
                        ),
                        if ((p.ciudad ?? '').isNotEmpty) ...[
                          Text('  ·  ',
                              style:
                                  AppTypography.bodySmall(color: nc.textMuted)),
                          Flexible(
                            child: Text(p.ciudad!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall(
                                    color: nc.textSecondary)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: nc.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
