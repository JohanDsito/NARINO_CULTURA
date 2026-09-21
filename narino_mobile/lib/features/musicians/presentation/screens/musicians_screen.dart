import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/musician_provider.dart';
import 'musicians_screen/genre_chips.dart';
import 'musicians_screen/musician_body.dart';
import 'musicians_screen/search_bar.dart';

class MusiciansScreen extends ConsumerStatefulWidget {
  const MusiciansScreen({super.key});

  @override
  ConsumerState<MusiciansScreen> createState() => _MusiciansScreenState();
}

class _MusiciansScreenState extends ConsumerState<MusiciansScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicianListProvider);
    final genresAsync = ref.watch(musicGenresProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      },
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Músicos',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note_outlined, color: AppColors.oroClaro),
            tooltip: 'Descubrimiento musical',
            onPressed: () => context.push('/music-discovery'),
          ),
        ],
      ),
      body: Column(
        children: [
          MusicianSearchBar(
            controller: _searchCtrl,
            isDark: isDark,
            onChanged: (v) =>
                ref.read(musicianListProvider.notifier).setSearch(v),
            onClear: () {
              setState(_searchCtrl.clear);
              ref.read(musicianListProvider.notifier).setSearch('');
            },
          ),
          genresAsync.when(
            data: (genres) => GenreChips(genres: genres, state: state),
            loading: () => const SizedBox(height: 40),
            error: (_, __) => const SizedBox(height: 40),
          ),
          Expanded(
            child: RefreshIndicator(
              color: cs.primary,
              onRefresh: () async =>
                  ref.read(musicianListProvider.notifier).load(),
              child: MusicianBody(state: state),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
