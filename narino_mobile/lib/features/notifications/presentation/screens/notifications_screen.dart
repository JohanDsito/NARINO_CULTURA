import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../providers/notifications_provider.dart';
import 'notifications_screen/empty_state.dart';
import 'notifications_screen/error_banner.dart';
import 'notifications_screen/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifs = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: AppTypography.displaySemiBold(),
        ),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).readAll(),
            child: Text(
              'Marcar todas como leídas',
              style: AppTypography.labelSemiBold(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async => ref.read(notificationsProvider.notifier).load(),
        child: asyncNotifs.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 140),
              Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 60),
              ErrorBanner(
                message: e.toString(),
                onRetry: () => ref.read(notificationsProvider.notifier).load(),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [EmptyState()],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => NotificationTile(
                notification: items[i],
                onTap: () async {
                  final n = items[i];
                  ref.read(notificationsProvider.notifier).markRead(n.id);
                  final route = n.ruta;
                  if (route != null) context.push(route);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

