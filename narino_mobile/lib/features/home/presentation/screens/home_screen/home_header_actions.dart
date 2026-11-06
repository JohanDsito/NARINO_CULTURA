import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/providers/theme_provider.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../marketplace/presentation/providers/cart_provider.dart';
import '../../../../notifications/presentation/providers/notifications_provider.dart';

/// Acciones del header de Inicio: carrito, notificaciones y modo claro/oscuro.
const homeHeaderActions = <Widget>[
  _CartAction(),
  _NotificationsAction(),
  _ThemeAction(),
];

class _CartAction extends ConsumerWidget {
  const _CartAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider.select((s) => s.items.length));
    return NcIconButton(
      icon: Icons.shopping_bag_outlined,
      tooltip: 'Carrito',
      badge: count,
      onPressed: () => context.push('/marketplace/cart'),
    );
  }
}

class _NotificationsAction extends ConsumerWidget {
  const _NotificationsAction();

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

class _ThemeAction extends ConsumerWidget {
  const _ThemeAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return NcIconButton(
      icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(brightness),
    );
  }
}
