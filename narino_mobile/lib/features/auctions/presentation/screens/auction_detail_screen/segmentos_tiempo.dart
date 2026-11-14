import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class SegmentosTiempo extends StatelessWidget {
  const SegmentosTiempo({
    super.key,
    required this.remaining,
    required this.titulo,
    required this.urgente,
  });

  final Duration remaining;
  final String titulo;
  final bool urgente;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final accent = urgente ? nc.enVivo : nc.subastas;
    final partes = <(int, String)>[
      (remaining.inDays, 'días'),
      (remaining.inHours.remainder(24), 'horas'),
      (remaining.inMinutes.remainder(60), 'min'),
      (remaining.inSeconds.remainder(60), 'seg'),
    ];
    return Semantics(
      label: '$titulo ${NcCountdown.spoken(remaining)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: AppTypography.labelMedium(color: nc.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < partes.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: urgente ? accent.fill : accent.tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          partes[i].$1.toString().padLeft(2, '0'),
                          style: AppTypography.displaySemiBold(
                                  color: urgente ? accent.onFill : accent.ink)
                              .copyWith(
                            fontSize: 22,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(partes[i].$2,
                            style: AppTypography.caption(
                                color: urgente
                                    ? accent.onFill
                                    : nc.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
