import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/musician_model.dart';
import '../providers/musician_provider.dart';
import '../widgets/musica_ui.dart';

class MusicianDetailScreen extends ConsumerWidget {
  const MusicianDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    return ref.watch(musicianDetailProvider(slug)).when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Músico')),
            body: ListView(children: [
              NcEmptyState(
                icon: Icons.music_off_outlined,
                accent: nc.tomateA,
                title: 'No pudimos abrir este perfil',
                message: e.toString(),
                actionLabel: 'Reintentar',
                onAction: () => ref.invalidate(musicianDetailProvider(slug)),
              ),
            ]),
          ),
          data: (m) => _Perfil(musician: m),
        );
  }
}

class _Perfil extends ConsumerWidget {
  const _Perfil({required this.musician});

  final MusicianModel musician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final m = musician;
    final seguidores = seguidoresVisibles(m, ref.watch(seguidosProvider));
    final miSlug = ref.watch(myMusicianSlugProvider).valueOrNull;
    final esMio = miSlug != null && miSlug == m.slug;
    final logueado = ref.watch(currentUserRoleProvider).valueOrNull != null;
    final detalle = [
      if (formatoAgrupacion(m.aggregationType).isNotEmpty)
        formatoAgrupacion(m.aggregationType),
      if ((m.city ?? '').isNotEmpty) m.city!,
    ].join(' · ');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: 170,
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
                    PortadaMusical(url: m.coverUrl, icon: Icons.graphic_eq_rounded),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x33000000), Color(0x00000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -1,
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: nc.bg,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Sin desplazar hacia arriba: la barra fija lo recortaba.
                        MusicoAvatar(musician: m, radius: 38),
                        const Spacer(),
                        if (!esMio) SeguirButton(musician: m),
                        if (esMio)
                          NcSecondaryButton(
                            label: 'Subir obra',
                            icon: Icons.add_rounded,
                            expand: false,
                            onPressed: () =>
                                context.push('/musicians/works/publish'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Flexible(
                          child: Text(m.name,
                              style: AppTypography.displayBlack(
                                      color: nc.textPrimary)
                                  .copyWith(fontSize: 28)),
                        ),
                        if (m.isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified_rounded,
                              color: nc.musica.ink, size: 22),
                        ],
                      ],
                    ),
                    if (detalle.isNotEmpty)
                      Text(detalle,
                          style:
                              AppTypography.bodyMedium(color: nc.textSecondary)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _Dato(valor: '$seguidores', label: 'seguidores'),
                        _Dato(
                            valor: m.reviewsCount > 0
                                ? m.averageRating.toStringAsFixed(1)
                                : '—',
                            label: 'calificación',
                            estrella: m.reviewsCount > 0),
                        _Dato(valor: '${m.reviewsCount}', label: 'reseñas'),
                      ],
                    ),
                    if ((m.bio ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(m.bio!.trim(),
                          style: AppTypography.bodyMedium(
                              color: nc.textSecondary)),
                    ],
                    if (m.genres.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final g in m.genres)
                            NcStatusPill(label: g, accent: nc.musica),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SliverPersistentHeader(pinned: true, delegate: _TabsDelegate()),
          ],
          body: TabBarView(
            children: [
              _Obras(slug: m.slug),
              _Resenas(musician: m, puedeResenar: logueado && !esMio),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.valor, required this.label, this.estrella = false});

  final String valor;
  final String label;
  final bool estrella;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(valor,
                  style: AppTypography.displaySemiBold(color: nc.textPrimary)),
              if (estrella) ...[
                const SizedBox(width: 2),
                Icon(Icons.star_rounded, size: 18, color: nc.oro),
              ],
            ],
          ),
          Text(label, style: AppTypography.bodySmall(color: nc.textSecondary)),
        ],
      ),
    );
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  const _TabsDelegate();

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return ColoredBox(
      color: context.nc.bg,
      child: const TabBar(tabs: [Tab(text: 'Obras'), Tab(text: 'Reseñas')]),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsDelegate old) => false;
}

// ─── Obras ──────────────────────────────────────────────────────────────────

class _Obras extends ConsumerWidget {
  const _Obras({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    return ref.watch(musicianWorksProvider(slug)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            NcEmptyState(
              icon: Icons.cloud_off_rounded,
              accent: nc.tomateA,
              title: 'No pudimos cargar las obras',
              message: e.toString(),
              actionLabel: 'Reintentar',
              onAction: () => ref.invalidate(musicianWorksProvider(slug)),
            ),
          ]),
          data: (obras) => obras.isEmpty
              ? ListView(children: [
                  NcEmptyState(
                    icon: Icons.library_music_outlined,
                    accent: nc.musica,
                    title: 'Aún no hay obras',
                    message: 'Cuando publique canciones o videos, aparecerán '
                        'aquí.',
                  ),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: obras.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ObraCard(obra: obras[i]),
                ),
        );
  }
}

class _ObraCard extends StatelessWidget {
  const _ObraCard({required this.obra});

  final MusicalWorkModel obra;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final o = obra;
    final enlaces = <(String, IconData, String)>[
      if ((o.youtubeUrl ?? '').isNotEmpty)
        ('YouTube', Icons.smart_display_outlined, o.youtubeUrl!),
      if ((o.spotifyTrackUrl ?? '').isNotEmpty)
        ('Spotify', Icons.graphic_eq_rounded, o.spotifyTrackUrl!),
      if ((o.audioUrl ?? '').isNotEmpty)
        ('Audio', Icons.play_circle_outline_rounded, o.audioUrl!),
      if (_urlDeEmbed(o.soundcloudEmbed) != null)
        ('SoundCloud', Icons.cloud_outlined, _urlDeEmbed(o.soundcloudEmbed)!),
    ];
    final meta = [
      if ((o.workType ?? '').isNotEmpty) _tipoObra(o.workType!),
      if (o.year != null) '${o.year}',
      if (o.durationSeconds != null)
        '${o.durationSeconds! ~/ 60}:${(o.durationSeconds! % 60).toString().padLeft(2, '0')}',
    ].join(' · ');

    return NcCard(
      padding: const EdgeInsets.all(12),
      gradientBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                    width: 64, height: 64, child: PortadaMusical(url: o.coverUrl)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.labelSemiBold(color: nc.textPrimary)),
                    if (meta.isNotEmpty)
                      Text(meta,
                          style:
                              AppTypography.bodySmall(color: nc.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          if ((o.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(o.description!.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall(color: nc.textSecondary)),
          ],
          if (enlaces.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, icon, url) in enlaces)
                  NcPressable(
                    onTap: () => launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication),
                    semanticLabel: 'Escuchar en $label',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: nc.musica.tint,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: nc.musica.fill.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: nc.musica.ink),
                          const SizedBox(width: 6),
                          Text(label,
                              style: AppTypography.labelMedium(
                                      color: nc.musica.ink)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Tipos del backend (`MusicalWork.WorkType`).
  static String _tipoObra(String t) => switch (t.toUpperCase()) {
        'VIDEO' => 'Video musical',
        'LIVE' => 'En vivo',
        'STUDIO' => 'Estudio',
        'COVER' => 'Cover',
        'PODCAST' => 'Podcast',
        _ => t,
      };

  /// El backend guarda el `<iframe>` de SoundCloud; se extrae su URL.
  static String? _urlDeEmbed(String? embed) {
    if (embed == null || embed.trim().isEmpty) return null;
    if (embed.startsWith('http')) return embed.trim();
    final m = RegExp(r'src="([^"]+)"').firstMatch(embed);
    return m?.group(1);
  }
}

// ─── Reseñas ────────────────────────────────────────────────────────────────

class _Resenas extends ConsumerWidget {
  const _Resenas({required this.musician, required this.puedeResenar});

  final MusicianModel musician;
  final bool puedeResenar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final async = ref.watch(musicianReviewsProvider(musician.slug));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ListView(children: [
        NcEmptyState(
          icon: Icons.cloud_off_rounded,
          accent: nc.tomateA,
          title: 'No pudimos cargar las reseñas',
          message: e.toString(),
        ),
      ]),
      data: (lista) {
        final promedio = lista.isEmpty
            ? 0.0
            : lista.fold<int>(0, (s, r) => s + r.rating) / lista.length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            NcCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(lista.isEmpty ? '—' : promedio.toStringAsFixed(1),
                      style: AppTypography.displayBlack(color: nc.oroA.ink)
                          .copyWith(fontSize: 40)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Estrellas(valor: promedio, size: 20),
                        const SizedBox(height: 2),
                        Text(
                          lista.isEmpty
                              ? 'Sin reseñas todavía'
                              : lista.length == 1
                                  ? '1 reseña'
                                  : '${lista.length} reseñas',
                          style:
                              AppTypography.bodySmall(color: nc.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (puedeResenar) ...[
              const SizedBox(height: 12),
              NcSecondaryButton(
                label: 'Escribir una reseña',
                icon: Icons.rate_review_outlined,
                onPressed: () => _abrirResena(context, ref, musician),
              ),
            ],
            const SizedBox(height: 16),
            for (final r in lista)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: nc.itemFill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: nc.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(r.reviewerName,
                                style: AppTypography.labelSemiBold(
                                        color: nc.textPrimary)
                                    .copyWith(fontSize: 14)),
                          ),
                          Estrellas(valor: r.rating.toDouble(), size: 14),
                        ],
                      ),
                      if ((r.comment ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(r.comment!.trim(),
                            style: AppTypography.bodyMedium(
                                color: nc.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

Future<void> _abrirResena(
    BuildContext context, WidgetRef ref, MusicianModel m) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ResenaSheet(musician: m),
  );
}

class _ResenaSheet extends ConsumerStatefulWidget {
  const _ResenaSheet({required this.musician});

  final MusicianModel musician;

  @override
  ConsumerState<_ResenaSheet> createState() => _ResenaSheetState();
}

class _ResenaSheetState extends ConsumerState<_ResenaSheet> {
  int _rating = 0;
  final _ctrl = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_rating == 0) {
      setState(() => _error = 'Elige de 1 a 5 estrellas.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref
          .read(musicianRepositoryProvider)
          .addReview(widget.musician.slug, _rating, _ctrl.text);
      ref.invalidate(musicianReviewsProvider(widget.musician.slug));
      ref.invalidate(musicianDetailProvider(widget.musician.slug));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Gracias por tu reseña!')));
    } catch (e) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Reseña para ${widget.musician.name}',
                style: AppTypography.displaySemiBold(color: nc.textPrimary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i estrella${i == 1 ? '' : 's'}',
                    iconSize: 40,
                    onPressed: () => setState(() => _rating = i),
                    icon: Icon(
                      _rating >= i
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: nc.oro,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              minLines: 3,
              maxLines: 6,
              maxLength: 600,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Cuéntanos tu experiencia (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              NcBanner.error(context, _error!),
            ],
            const SizedBox(height: 16),
            NcPrimaryButton(
              label: 'Publicar reseña',
              loading: _enviando,
              onPressed: _enviar,
            ),
          ],
        ),
      ),
    );
  }
}
