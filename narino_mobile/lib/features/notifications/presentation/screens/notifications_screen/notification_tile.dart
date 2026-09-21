import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/notification_model.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

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
                  color: isUnread
                      ? (isDark ? AppColors.indigoDark : AppColors.indigoNoche)
                      : Colors.transparent,
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
