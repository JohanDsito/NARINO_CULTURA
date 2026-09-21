import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../notifications/presentation/providers/notifications_provider.dart';
import 'notification_bell.dart';

// ─── AppBar ───────────────────────────────────────────────────────────────────

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({required this.ref, super.key});

  final WidgetRef ref;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return AppBar(
      backgroundColor: AppColors.obsidiana,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.oroAndino,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.landscape_outlined,
                color: AppColors.obsidiana, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            'Nariño Cultura',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.oroClaro,
            ),
          ),
        ],
      ),
      actions: [
        NotificationBell(unread: unread),
        IconButton(
          icon: const Icon(Icons.person_outline, color: AppColors.oroClaro),
          onPressed: () => context.push('/profile'),
        ),
      ],
    );
  }
}
