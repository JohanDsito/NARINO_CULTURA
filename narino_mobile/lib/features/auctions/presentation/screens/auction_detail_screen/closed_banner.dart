import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/auction_model.dart';

class ClosedBanner extends StatelessWidget {
  const ClosedBanner({super.key, required this.auction});

  final AuctionModel auction;

  @override
  Widget build(BuildContext context) {
    final winner = auction.ganadorNombre?.trim() ?? '';
    final hasWinner = winner.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.oroAndino,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined,
              color: AppColors.obsidiana, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasWinner
                  ? 'Ganador: $winner · Final \$${auction.precioActual.toStringAsFixed(0)}'
                  : 'Sin pujas — subasta cerrada',
              style: AppTypography.bodyMedium(color: AppColors.obsidiana),
            ),
          ),
        ],
      ),
    );
  }
}
