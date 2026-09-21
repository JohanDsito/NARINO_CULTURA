import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../ai/data/ai_service.dart';
import '../providers/profile_provider.dart';
import 'artist_stats_screen/empty_top.dart';
import 'artist_stats_screen/error_banner.dart';
import 'artist_stats_screen/income_card.dart';
import 'artist_stats_screen/not_artist_state.dart';
import 'artist_stats_screen/stat_grid.dart';
import 'artist_stats_screen/top_artwork.dart';
import 'artist_stats_screen/top_artwork_tile.dart';

final _artistStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final slug = ref.watch(myProfileProvider).profile?.id ?? '';
  return AiService().getArtistStats(artistSlug: slug.isNotEmpty ? slug : null);
});

class ArtistStatsScreen extends ConsumerWidget {
  const ArtistStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).profile;
    final isArtist = (profile?.disciplina.trim().isNotEmpty ?? false);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Mis estadísticas',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: !isArtist
          ? const NotArtistState()
          : ref
                .watch(_artistStatsProvider)
                .when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  ),
                  error: (e, _) => ErrorBanner(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(_artistStatsProvider),
                  ),
                  data: (data) {
                    final visitasMes = _asInt(data['visitas_mes']);
                    final visitasTotal = _asInt(data['visitas_total']);
                    final nuevosSeguidores = _asInt(data['nuevos_seguidores']);
                    final ingresosMes = _asMoney(data['ingresos_mes']);
                    final top = _parseTop(data['obras_mas_vistas']);

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      children: [
                        StatGrid(
                          visitasMes: visitasMes,
                          visitasTotal: visitasTotal,
                          nuevosSeguidores: nuevosSeguidores,
                        ),
                        const SizedBox(height: 12),
                        IncomeCard(
                          value: ingresosMes,
                          onGoSales: () => context.push('/marketplace/sales'),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Obras más vistas',
                          style: AppTypography.displaySemiBold(
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (top.isEmpty)
                          const EmptyTop()
                        else
                          ...top
                              .take(5)
                              .map(
                                (a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: TopArtworkTile(artwork: a),
                                ),
                              ),
                      ],
                    );
                  },
                ),
    );
  }

  int _asInt(Object? v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  String _asMoney(Object? v) {
    final d = double.tryParse(v?.toString() ?? '') ?? 0;
    final n = d
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }

  List<TopArtwork> _parseTop(Object? raw) {
    if (raw is! List) return const <TopArtwork>[];
    return raw
        .whereType<Map>()
        .map((m) => TopArtwork.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}
