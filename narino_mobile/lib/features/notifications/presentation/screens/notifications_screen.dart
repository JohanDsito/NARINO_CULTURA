import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/notification_model.dart';
import '../providers/notifications_provider.dart';

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
                    _Filtro(
                      label: 'Todas',
                      selected: !_soloSinLeer,
                      onTap: () => setState(() => _soloSinLeer = false),
                    ),
                    const SizedBox(width: 8),
                    _Filtro(
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
                    _Fila(
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

/// Ícono y color según `type` (AUCTION_*, EVENT_*, ORDER_*, PAYMENT_*).
(IconData, NcAccent) _estilo(NcColors nc, String tipo) {
  final t = tipo.toUpperCase();
  return switch (t) {
    'AUCTION_BID' => (Icons.gavel_rounded, nc.oroA),
    'AUCTION_CLOSED' => (Icons.emoji_events_outlined, nc.oroA),
    'AUCTION_OPENED' => (Icons.campaign_outlined, nc.oroA),
    'AUCTION_PENDING' => (Icons.hourglass_top_rounded, nc.oroA),
    'AUCTION_REJECTED' => (Icons.block_rounded, nc.tomateA),
    'AUCTION_PAYMENT_EXPIRED' => (Icons.timer_off_outlined, nc.tomateA),
    'EVENT_REGISTRATION' => (Icons.event_available_rounded, nc.eventos),
    _ when t.startsWith('EVENT') => (Icons.event_rounded, nc.eventos),
    _ when t.startsWith('ORDER') || t.startsWith('PAYMENT') =>
      (Icons.shopping_bag_outlined, nc.tienda),
    _ when t.startsWith('AUCTION') => (Icons.gavel_rounded, nc.oroA),
    _ => (Icons.notifications_none_rounded, nc.azulA),
  };
}

String _cuando(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'Ayer';
  if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
  return '${d.day} ${kMesesNombre[d.month - 1].substring(0, 3).toLowerCase()}';
}

class _Fila extends StatelessWidget {
  const _Fila({required this.n, required this.onTap});

  final NotificationModel n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final (icon, accent) = _estilo(nc, n.tipo);
    final nueva = !n.leida;
    return Semantics(
      button: true,
      label: '${nueva ? 'Sin leer. ' : ''}${n.titulo}. ${n.descripcion}. '
          '${_cuando(n.creadoEn)}',
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: nueva ? Color.alphaBlend(accent.tint, nc.bgCard) : nc.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: nueva ? accent.fill.withValues(alpha: 0.45) : nc.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NcAccentIcon(icon: icon, accent: accent, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(n.titulo,
                              style: AppTypography.labelSemiBold(
                                      color: nc.textPrimary)
                                  .copyWith(
                                      fontWeight: nueva
                                          ? FontWeight.w700
                                          : FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Text(_cuando(n.creadoEn),
                            style: AppTypography.bodySmall(
                                color: nueva ? accent.ink : nc.textMuted)),
                      ],
                    ),
                    if (n.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(n.descripcion,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(
                              color: nc.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (nueva) ...[
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                      color: nc.azul, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = nc.azulA;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? a.fill : nc.itemFill,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? a.fill : nc.border),
          ),
          child: Text(label,
              style: AppTypography.labelMedium(
                      color: selected ? a.onFill : nc.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
