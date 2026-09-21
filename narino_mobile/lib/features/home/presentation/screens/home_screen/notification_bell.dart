import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({required this.unread, super.key});

  final int unread;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: AppColors.oroClaro),
          onPressed: () => context.push('/notifications'),
        ),
        if (unread > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: AppTypography.caption(
                    color: Theme.of(context).colorScheme.onError,
                  ).copyWith(fontSize: 9),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
