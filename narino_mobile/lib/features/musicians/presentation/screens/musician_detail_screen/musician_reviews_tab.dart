import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/musician_model.dart';
import '../../providers/musician_provider.dart';
import '../../widgets/musica_ui.dart';
import 'review_sheet.dart';

// ─── Reseñas ────────────────────────────────────────────────────────────────

class MusicianReviewsTab extends ConsumerWidget {
  const MusicianReviewsTab(
      {super.key, required this.musician, required this.puedeResenar});

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
    builder: (_) => ReviewSheet(musician: m),
  );
}
