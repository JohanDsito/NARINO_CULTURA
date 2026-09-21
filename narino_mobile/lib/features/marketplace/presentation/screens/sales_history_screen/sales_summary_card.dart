import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'summary_stat.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtCOP(double value) {
  final n = value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  return '\$$n COP';
}

// ─── Card de resumen ──────────────────────────────────────────────────────────

class SalesSummaryCard extends StatelessWidget {
  const SalesSummaryCard({
    super.key,
    required this.totalMes,
    required this.totalHistorico,
    required this.completadasCount,
  });

  final double totalMes;
  final double totalHistorico;
  final int completadasCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.obsidiana,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de ventas',
            style:
                AppTypography.caption(color: AppColors.oroClaro.withAlpha(70)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SummaryStat(
                  label: 'Este mes',
                  value: _fmtCOP(totalMes),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.oroClaro.withAlpha(20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SummaryStat(
                  label: 'Total histórico',
                  value: _fmtCOP(totalHistorico),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.oroClaro.withAlpha(20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SummaryStat(
                  label: 'Completadas',
                  value: '$completadasCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
