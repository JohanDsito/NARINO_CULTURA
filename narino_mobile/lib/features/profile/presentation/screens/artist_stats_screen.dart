import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../ai/data/ai_service.dart';
import '../providers/profile_provider.dart';

final _artistStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return AiService().getArtistStats();
});

class ArtistStatsScreen extends ConsumerWidget {
  const ArtistStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).profile;
    final isArtist = (profile?.disciplina.trim().isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Mis estadísticas',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: !isArtist
          ? const _NotArtistState()
          : ref.watch(_artistStatsProvider).when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.tierraProfunda),
                ),
                error: (e, _) => _ErrorBanner(
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
                      _StatGrid(
                        visitasMes: visitasMes,
                        visitasTotal: visitasTotal,
                        nuevosSeguidores: nuevosSeguidores,
                      ),
                      const SizedBox(height: 12),
                      _IncomeCard(
                        value: ingresosMes,
                        onGoSales: () => context.push('/marketplace/sales'),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Obras más vistas',
                        style: AppTypography.displaySemiBold(
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (top.isEmpty)
                        const _EmptyTop()
                      else
                        ...top.take(5).map(
                              (a) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _TopArtworkTile(artwork: a),
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
    final n = d.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
    return '\$$n COP';
  }

  List<_TopArtwork> _parseTop(Object? raw) {
    if (raw is! List) return const <_TopArtwork>[];
    return raw
        .whereType<Map>()
        .map((m) => _TopArtwork.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.visitasMes,
    required this.visitasTotal,
    required this.nuevosSeguidores,
  });

  final int visitasMes;
  final int visitasTotal;
  final int nuevosSeguidores;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Visitas este mes',
                value: '$visitasMes',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Visitas total',
                value: '$visitasTotal',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Nuevos seguidores',
                value: '$nuevosSeguidores',
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption(color: AppColors.textMutedLight),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.price(color: AppColors.oroAndino),
          ),
        ],
      ),
    );
  }
}

class _IncomeCard extends StatelessWidget {
  const _IncomeCard({required this.value, required this.onGoSales});

  final String value;
  final VoidCallback onGoSales;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ingresos del mes',
                  style: AppTypography.caption(color: AppColors.textMutedLight),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppTypography.price(color: AppColors.tierraProfunda),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onGoSales,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.tierraProfunda,
              side: const BorderSide(color: AppColors.borderLight),
            ),
            child: Text(
              'Ver detalle',
              style: AppTypography.labelSemiBold(color: AppColors.tierraProfunda),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopArtworkTile extends StatelessWidget {
  const _TopArtworkTile({required this.artwork});

  final _TopArtwork artwork;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: InkWell(
        onTap: artwork.id == null ? null : () => context.push('/artworks/${artwork.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: artwork.imageUrl == null
                    ? Container(
                        width: 54,
                        height: 54,
                        color: AppColors.bgSubtleLight,
                        child: const Icon(Icons.image_outlined, color: AppColors.borderLight),
                      )
                    : Image.network(
                        artwork.imageUrl!,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 54,
                          height: 54,
                          color: AppColors.bgSubtleLight,
                          child: const Icon(Icons.image_not_supported_outlined, color: AppColors.borderLight),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.title ?? 'Obra',
                      style: AppTypography.labelSemiBold(color: AppColors.textPrimaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${artwork.visits} visitas',
                      style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMutedLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTop extends StatelessWidget {
  const _EmptyTop();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_outlined, color: AppColors.textMutedLight, size: 72),
            const SizedBox(height: 12),
            Text(
              'Aún no hay datos suficientes',
              style: AppTypography.displaySemiBold(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Publica y comparte tus obras para ver estadísticas.',
              style: AppTypography.bodySmall(color: AppColors.textMutedLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotArtistState extends StatelessWidget {
  const _NotArtistState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_outlined, color: AppColors.textMutedLight, size: 72),
            const SizedBox(height: 16),
            Text(
              'Estadísticas disponibles para artistas',
              style: AppTypography.displaySemiBold(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Completa tu perfil como artista para ver visitas, seguidores e ingresos.',
              style: AppTypography.bodySmall(color: AppColors.textMutedLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 44),
              const SizedBox(height: 10),
              Text(
                message,
                style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tierraProfunda,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Reintentar',
                    style: AppTypography.labelSemiBold(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopArtwork {
  const _TopArtwork({required this.id, required this.title, required this.imageUrl, required this.visits});

  final int? id;
  final String? title;
  final String? imageUrl;
  final int visits;

  factory _TopArtwork.fromJson(Map<String, dynamic> json) {
    int? parseId(Object? v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '');
    }

    int parseVisits(Object? v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return _TopArtwork(
      id: parseId(json['id'] ?? json['obra_id'] ?? json['artwork_id']),
      title: (json['titulo'] ?? json['title'] ?? '').toString().trim().isEmpty
          ? null
          : (json['titulo'] ?? json['title']).toString(),
      imageUrl: (json['imagen_url'] ?? json['image_url'] ?? json['imagen'] ?? json['image'])?.toString(),
      visits: parseVisits(json['visitas'] ?? json['views']),
    );
  }
}

