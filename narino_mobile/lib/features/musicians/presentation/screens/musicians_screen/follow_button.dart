import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/musician_model.dart';
import '../../providers/musician_provider.dart';

class FollowButton extends ConsumerWidget {
  const FollowButton({super.key, required this.musician});

  final MusicianModel musician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = musician.isFollowing;

    return GestureDetector(
      onTap: () =>
          ref.read(musicianListProvider.notifier).toggleFollow(musician.slug),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing
              ? AppColors.indigoClaro.withValues(alpha: 0.12)
              : AppColors.indigoClaro,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.indigoClaro),
        ),
        child: Text(
          isFollowing ? 'Siguiendo' : 'Seguir',
          style: AppTypography.caption(
            color:
                isFollowing ? AppColors.indigoClaro : Colors.white,
          ),
        ),
      ),
    );
  }
}
