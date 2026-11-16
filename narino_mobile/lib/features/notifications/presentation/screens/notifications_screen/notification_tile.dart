import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/notification_model.dart';

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
    _ when t.startsWith('ORDER') || t.startsWith('PAYMENT') => (
        Icons.shopping_bag_outlined,
        nc.tienda
      ),
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

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.n, required this.onTap});

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
      onTap: onTap,
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
                          style:
                              AppTypography.bodySmall(color: nc.textSecondary)),
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
                  decoration:
                      BoxDecoration(color: nc.azul, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
