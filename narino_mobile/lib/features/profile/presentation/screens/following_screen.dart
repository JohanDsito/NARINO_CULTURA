import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/profile_model.dart';
import '../providers/profile_provider.dart';
import '../widgets/disciplinas.dart';

enum _Filtro { todos, artistas, musicos }

/// Artistas y músicos que sigue la persona.
class FollowingScreen extends ConsumerStatefulWidget {
  const FollowingScreen({super.key});

  @override
  ConsumerState<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends ConsumerState<FollowingScreen> {
  _Filtro _filtro = _Filtro.todos;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final async = ref.watch(followingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Siguiendo')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [
          NcEmptyState(
            icon: Icons.wifi_off_rounded,
            accent: nc.tomateA,
            title: 'No pudimos cargar a quién sigues',
            message: 'Revisa tu conexión e intenta de nuevo.',
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(followingProvider),
          ),
        ]),
        data: (todos) {
          if (todos.isEmpty) return const _Vacio();
          final artistas = todos.where((p) => !p.esMusico).length;
          final musicos = todos.length - artistas;
          final lista = switch (_filtro) {
            _Filtro.todos => todos,
            _Filtro.artistas => todos.where((p) => !p.esMusico).toList(),
            _Filtro.musicos => todos.where((p) => p.esMusico).toList(),
          };
          return RefreshIndicator(
            onRefresh: () => ref.refresh(followingProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (artistas > 0 && musicos > 0) ...[
                  SegmentedButton<_Filtro>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: _Filtro.todos,
                          label: Text('Todos ${todos.length}')),
                      ButtonSegment(
                          value: _Filtro.artistas,
                          label: Text('Artistas $artistas')),
                      ButtonSegment(
                          value: _Filtro.musicos,
                          label: Text('Música $musicos')),
                    ],
                    selected: {_filtro},
                    onSelectionChanged: (s) =>
                        setState(() => _filtro = s.first),
                  ),
                  const SizedBox(height: 16),
                ] else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
                    child: Text(
                      todos.length == 1
                          ? 'Sigues a 1 perfil'
                          : 'Sigues a ${todos.length} perfiles',
                      style: AppTypography.bodySmall(color: nc.textSecondary),
                    ),
                  ),
                for (final p in lista) ...[
                  _Fila(perfil: p),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.perfil});

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
        onTap: () => context.push(
            p.esMusico ? '/musicians/${p.id}' : '/artistas/${p.id}'),
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
                          style: AppTypography.displaySemiBold(
                              color: accent.ink))
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
                        Icon(p.esMusico
                                ? Icons.music_note_rounded
                                : (d?.icon ?? Icons.palette_outlined),
                            size: 14,
                            color: accent.ink),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall(
                                  color: accent.ink)),
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

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      children: [
        Center(
          child: NcAccentIcon(
              icon: Icons.favorite_border_rounded,
              accent: nc.catalogo,
              size: 72,
              glow: true),
        ),
        const SizedBox(height: 20),
        Text('Todavía no sigues a nadie',
            textAlign: TextAlign.center,
            style: AppTypography.displaySemiBold(color: nc.textPrimary)),
        const SizedBox(height: 8),
        Text(
          'Sigue a artistas y músicos de Nariño para enterarte de sus obras '
          'nuevas, subastas y conciertos.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium(color: nc.textSecondary),
        ),
        const SizedBox(height: 24),
        NcPrimaryButton(
          label: 'Explorar el catálogo',
          icon: Icons.palette_outlined,
          onPressed: () => context.go('/catalog'),
        ),
        const SizedBox(height: 10),
        NcSecondaryButton(
          label: 'Descubrir música',
          icon: Icons.music_note_rounded,
          onPressed: () => context.push('/musicians'),
        ),
      ],
    );
  }
}
