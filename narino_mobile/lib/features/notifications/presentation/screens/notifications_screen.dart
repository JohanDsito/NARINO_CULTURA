import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/notification_model.dart';
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
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Notificaciones',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).readAll(),
            child: Text(
              'Marcar todas como leídas',
              style: AppTypography.labelSemiBold(color: AppColors.oroClaro),
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
                  final route = _routeFor(n);
                  if (route != null) context.push(route);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  String? _routeFor(NotificationModel n) {
    final t = n.tipo.toLowerCase().trim();
    final id = n.referenciaId;
    if (id == null) return null;

    if (t.contains('obra') || t.contains('artwork')) return '/artworks/$id';
    if (t.contains('subasta') || t.contains('auction')) return '/auctions/$id';
    if (t.contains('compra') || t.contains('order')) {
      return '/marketplace/order/$id';
    }
    if (t.contains('evento') || t.contains('event')) return '/events/$id';
    return null;
  }
}

