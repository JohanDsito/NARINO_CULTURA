import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/musician_provider.dart';
import 'musician_detail_screen/musician_sliver_app_bar.dart';
import 'musician_detail_screen/reviews_tab.dart';
import 'musician_detail_screen/works_tab.dart';

class MusicianDetailScreen extends ConsumerStatefulWidget {
  const MusicianDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<MusicianDetailScreen> createState() =>
      _MusicianDetailScreenState();
}

class _MusicianDetailScreenState extends ConsumerState<MusicianDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicianAsync = ref.watch(musicianDetailProvider(widget.slug));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: musicianAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.indigoClaro),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_off_outlined,
                  size: 48, color: AppColors.indigoClaro),
              const SizedBox(height: 12),
              Text(e.toString(),
                  style: AppTypography.bodyMedium(color: AppColors.error),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(musicianDetailProvider(widget.slug)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigoClaro,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (musician) => NestedScrollView(
          headerSliverBuilder: (context, _) => [
            MusicianSliverAppBar(musician: musician, isDark: isDark),
          ],
          body: Column(
            children: [
              TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.indigoClaro,
                unselectedLabelColor: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
                indicatorColor: AppColors.indigoClaro,
                tabs: const [
                  Tab(text: 'Obras'),
                  Tab(text: 'Reseñas'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    WorksTab(slug: widget.slug),
                    ReviewsTab(slug: widget.slug),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
