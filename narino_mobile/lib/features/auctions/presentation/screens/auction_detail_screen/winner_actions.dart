import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../domain/auction_model.dart';

class WinnerActions extends ConsumerWidget {
  const WinnerActions({
    super.key,
    required this.auction,
    required this.isWinnerFn,
    required this.isArtistFn,
  });

  final AuctionModel auction;
  final bool Function(AuctionModel, {required String? myId}) isWinnerFn;
  final bool Function(AuctionModel,
      {required String myName, required String? myId}) isArtistFn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (auction.estado == 'activa') return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return FutureBuilder(
      future: ref.read(profileRepositoryProvider).getMyProfile(),
      builder: (context, snapshot) {
        final me = snapshot.data;
        final myId = me?.id;
        final myName = me?.nombreArtistico ?? '';

        final isWinner = isWinnerFn(auction, myId: myId);
        final isArtist = me == null
            ? false
            : isArtistFn(auction, myName: myName, myId: myId);

        if (isWinner) {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                final orderId = auction.orderId;
                if (orderId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No se encontró la orden para pago.')),
                  );
                  return;
                }
                context.push('/marketplace/checkout?orderId=$orderId');
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(
                'Completar pago',
                style: AppTypography.buttonText(color: Colors.white),
              ),
            ),
          );
        }

        if (isArtist) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tu subasta cerró. Revisa el resultado en tu historial.',
                    style: AppTypography.bodyMedium(color: textSecondary),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
