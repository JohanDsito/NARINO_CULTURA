import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/musician_model.dart';
import '../../providers/musician_provider.dart';

class FollowDetailButton extends ConsumerWidget {
  const FollowDetailButton({super.key, required this.musician});

  final MusicianModel musician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = musician.isFollowing;

    return GestureDetector(
      onTap: () async {
        await ref
            .read(musicianRepositoryProvider)
            .toggleFollow(musician.slug);
        ref.invalidate(musicianDetailProvider(musician.slug));
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isFollowing
              ? Colors.white.withValues(alpha: 0.15)
              : AppColors.indigoClaro,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isFollowing
                ? Colors.white.withValues(alpha: 0.5)
                : AppColors.indigoClaro,
          ),
        ),
        child: Text(
          isFollowing ? 'Siguiendo' : 'Seguir',
          style: AppTypography.caption(color: Colors.white),
        ),
      ),
    );
  }
}
