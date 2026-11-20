import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/widgets/design/design.dart';
import '../../../../notifications/presentation/providers/notifications_provider.dart';

class NotificationsHeaderAction extends ConsumerWidget {
  const NotificationsHeaderAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    return NcIconButton(
      icon: Icons.notifications_none_rounded,
      tooltip: 'Notificaciones',
      badge: unread,
      onPressed: () => context.push('/notifications'),
    );
  }
}
