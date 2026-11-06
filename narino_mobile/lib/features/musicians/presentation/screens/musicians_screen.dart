import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/musician_model.dart';
import '../providers/musician_provider.dart';
import '../widgets/musica_ui.dart';

/// Directorio de músicos (acento azul: música).
class MusiciansScreen extends ConsumerStatefulWidget {
  const MusiciansScreen({super.key});

  @override
  ConsumerState<MusiciansScreen> createState() => _MusiciansScreenState();
}

class _MusiciansScreenState extends ConsumerState<MusiciansScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = ref.read(musicianListProvider).search;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Busca al dejar de escribir (antes: 1 petición por letra).
  void _buscar(String v) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450),
        () => ref.read(musicianListProvider.notifier).setSearch(v.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final state = ref.watch(musicianListProvider);
    final generos = ref.watch(musicGenresProvider).valueOrNull ??
        const <MusicGenreModel>[];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.canPop() ? context.pop() : context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MÚSICA DE NARIÑO',
                  style: AppTypography.caption(color: nc.musica.ink)
                      .copyWith(letterSpacing: 0.8)),
              const Text('Músicos'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(musicianListProvider.notifier).load();
            await ref.read(seguidosProvider.notifier).cargar();
          },
          child: ListView(
            padding: const EdgeInsets.only(top: 14, bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Buscador(
                  controller: _searchCtrl,
                  onChanged: _buscar,
                  onClear: () {
                    _searchCtrl.clear();
                    _buscar('');
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (generos.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: generos.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final g = i == 0 ? null : generos[i - 1];
                      final sel = state.genreFilter == g?.slug;
                      return ChoiceChip(
                        label: Text(g?.name ?? 'Todos'),
                        selected: sel,
                        showCheckmark: false,
                        onSelected: (_) => ref
                            .read(musicianListProvider.notifier)
                            .setGenre(sel || g == null ? null : g.slug),
                        selectedColor: nc.musica.fill,
                        backgroundColor: nc.bgGlass,
                        side: BorderSide(
                            color: sel ? nc.musica.fill : nc.border),
                        labelStyle: AppTypography.labelMedium(
                                color: sel ? nc.musica.onFill : nc.textPrimary)
                            .copyWith(fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DescubrirBanner(
                    onTap: () => context.push('/music-discovery')),
              ),
              const SizedBox(height: 20),
              if (state.isLoading && state.musicians.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.hasError && state.musicians.isEmpty)
                NcEmptyState(
                  icon: Icons.cloud_off_rounded,
                  accent: nc.tomateA,
                  title: 'No pudimos cargar los músicos',
                  message: state.errorMessage!,
                  actionLabel: 'Reintentar',
                  onAction: () =>
                      ref.read(musicianListProvider.notifier).load(),
                )
              else if (state.musicians.isEmpty)
                NcEmptyState(
                  icon: Icons.music_off_outlined,
                  accent: nc.musica,
                  title: 'No encontramos músicos',
                  message: 'Prueba con otro nombre o quita el filtro de '
                      'género.',
                  actionLabel: 'Ver todos',
                  onAction: () {
                    _searchCtrl.clear();
                    ref.read(musicianListProvider.notifier).clearFilters();
                  },
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    state.musicians.length == 1
                        ? '1 artista'
                        : '${state.musicians.length} artistas',
                    style: AppTypography.labelMedium(color: nc.textSecondary),
                  ),
                ),
                for (final m in state.musicians)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: MusicoCard(musician: m),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Buscador extends StatelessWidget {
  const _Buscador({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(99),
      borderSide: BorderSide(color: nc.border),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar artistas, ciudades o géneros',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar búsqueda',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: pill,
        enabledBorder: pill,
        focusedBorder: pill.copyWith(
            borderSide: BorderSide(color: nc.musica.fill, width: 1.5)),
      ),
    );
  }
}

class _DescubrirBanner extends StatelessWidget {
  const _DescubrirBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return NcCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          NcAccentIcon(
              icon: Icons.auto_awesome_rounded,
              accent: nc.musica,
              size: 52,
              glow: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descubre tu sonido',
                    style: AppTypography.displaySemiBold(color: nc.textPrimary)
                        .copyWith(fontSize: 17)),
                const SizedBox(height: 2),
                Text('Cuéntanos qué quieres escuchar y te recomendamos '
                    'artistas de Nariño.',
                    style: AppTypography.bodySmall(color: nc.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: nc.musica.ink),
        ],
      ),
    );
  }
}
