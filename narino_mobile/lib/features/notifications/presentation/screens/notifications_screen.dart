import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/notification_model.dart';
import '../providers/notifications_provider.dart';
import 'notifications_screen/notification_filter_chip.dart';
import 'notifications_screen/notification_tile.dart';

/// Bandeja de notificaciones (`/notifications/`). Cada tipo lleva el color de
/// su sección: subastas oro, eventos tomate, compras naranja.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _soloSinLeer = false;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final async = ref.watch(notificationsProvider);
    final todas = async.valueOrNull ?? const <NotificationModel>[];
    final sinLeer = todas.where((n) => !n.leida).length;
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (sinLeer > 0)
            IconButton(
              tooltip: 'Marcar todas como leídas',
              icon: const Icon(Icons.done_all_rounded),
              onPressed: notifier.readAll,
            ),
          IconButton(
            tooltip: 'Avisos de eventos',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push('/events/notification-preferences'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.load,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              NcEmptyState(
                icon: Icons.wifi_off_rounded,
                accent: nc.tomateA,
                title: 'No pudimos cargar tus notificaciones',
                message: e.toString(),
                actionLabel: 'Reintentar',
                onAction: notifier.load,
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  NcEmptyState(
                    icon: Icons.notifications_none_rounded,
                    accent: nc.oroA,
                    title: 'Estás al día',
                    message: 'Aquí te avisaremos de pujas, compras y eventos '
                        'a los que te inscribas.',
                  ),
                ],
              );
            }
            final lista =
                _soloSinLeer ? items.where((n) => !n.leida).toList() : items;
            final grupos = _agrupar(lista);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                Row(
                  children: [
                    NotificationFilterChip(
                      label: 'Todas',
                      selected: !_soloSinLeer,
                      onTap: () => setState(() => _soloSinLeer = false),
                    ),
                    const SizedBox(width: 8),
                    NotificationFilterChip(
                      label: sinLeer > 0 ? 'Sin leer · $sinLeer' : 'Sin leer',
                      selected: _soloSinLeer,
                      onTap: () => setState(() => _soloSinLeer = true),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (lista.isEmpty)
                  NcEmptyState(
                    icon: Icons.mark_email_read_outlined,
                    accent: nc.successA,
                    title: 'Ya leíste todo',
                    message: 'No tienes notificaciones pendientes.',
                    padding: const EdgeInsets.only(top: 32),
                  ),
                for (final g in grupos) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                    child: Text(g.$1.toUpperCase(),
                        style: AppTypography.labelMedium(color: nc.textMuted)
                            .copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1)),
                  ),
                  for (final n in g.$2) ...[
                    NotificationTile(
                      n: n,
                      onTap: () {
                        notifier.markRead(n.id);
                        final r = n.ruta;
                        if (r != null) context.push(r);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Hoy / Esta semana / Antes, conservando el orden del backend.
  static List<(String, List<NotificationModel>)> _agrupar(
      List<NotificationModel> items) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final semana = hoy.subtract(const Duration(days: 6));
    final out = <String, List<NotificationModel>>{};
    for (final n in items) {
      final d = n.creadoEn;
      final k = !d.isBefore(hoy)
          ? 'Hoy'
          : (!d.isBefore(semana) ? 'Esta semana' : 'Antes');
      (out[k] ??= []).add(n);
    }
    return [
      for (final k in const ['Hoy', 'Esta semana', 'Antes'])
        if (out[k] != null) (k, out[k]!),
    ];
  }
}
