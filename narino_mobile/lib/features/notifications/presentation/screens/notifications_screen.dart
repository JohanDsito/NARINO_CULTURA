import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/notification_model.dart';
import '../providers/notifications_provider.dart';

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
        color: AppColors.tierraProfunda,
        onRefresh: () async => ref.read(notificationsProvider.notifier).load(),
        child: asyncNotifs.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 140),
              Center(
                child:
                    CircularProgressIndicator(color: AppColors.tierraProfunda),
              ),
            ],
          ),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 60),
              _ErrorBanner(
                message: e.toString(),
                onRetry: () => ref.read(notificationsProvider.notifier).load(),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [_EmptyState()],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _NotificationTile(
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final unreadBg = isDark
        ? AppColors.indigoNoche.withValues(alpha: 0.20)
        : AppColors.indigoPalido.withValues(alpha: 0.20);
    final isUnread = !notification.leida;
    final icon = _iconForType(notification.tipo);
    final timeText = _formatWhen(notification.creadoEn);

    return Container(
      decoration: BoxDecoration(
        color: isUnread ? unreadBg : bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: isUnread ? AppColors.indigoNoche : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.titulo,
                            style: AppTypography.labelSemiBold(
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeText,
                          style: AppTypography.caption(
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.descripcion,
                      style: AppTypography.bodySmall(
                        color: textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('obra') || t.contains('artwork')) {
      return Icons.palette_outlined;
    }
    if (t.contains('subasta') || t.contains('auction')) {
      return Icons.gavel_outlined;
    }
    if (t.contains('compra') || t.contains('order')) {
      return Icons.shopping_bag_outlined;
    }
    if (t.contains('evento') || t.contains('event')) {
      return Icons.event_outlined;
    }
    return Icons.notifications_outlined;
  }

  String _formatWhen(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';

    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 44),
              const SizedBox(height: 10),
              Text(
                message,
                style: AppTypography.bodyMedium(color: textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Reintentar',
                    style: AppTypography.labelSemiBold(color: cs.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined, color: textMuted, size: 72),
            const SizedBox(height: 16),
            Text(
              'No tienes notificaciones',
              style: AppTypography.displaySemiBold(
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando haya actividad importante, aparecerá aquí.',
              style: AppTypography.bodySmall(color: textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
