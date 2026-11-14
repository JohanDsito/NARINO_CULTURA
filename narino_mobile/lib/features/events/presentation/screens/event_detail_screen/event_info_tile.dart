import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class EventInfoTile extends StatelessWidget {
  const EventInfoTile({
    super.key,
    required this.icon,
    required this.accent,
    required this.titulo,
    required this.texto,
    this.accion,
    this.onAccion,
  });

  final IconData icon;
  final NcAccent accent;
  final String titulo;
  final String texto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return NcCard(
      padding: const EdgeInsets.all(14),
      gradientBorder: false,
      onTap: onAccion,
      child: Row(
        children: [
          NcAccentIcon(icon: icon, accent: accent, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo.toUpperCase(),
                    style: AppTypography.caption(color: nc.textMuted)
                        .copyWith(letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text(texto,
                    style: AppTypography.labelSemiBold(color: nc.textPrimary)
                        .copyWith(fontSize: 15, height: 1.3)),
                if (accion != null) ...[
                  const SizedBox(height: 4),
                  Text(accion!,
                      style: AppTypography.labelMedium(color: nc.azul)
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
