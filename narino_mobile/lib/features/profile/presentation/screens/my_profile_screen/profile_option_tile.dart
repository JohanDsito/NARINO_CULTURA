import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class ProfileOptionTile extends StatelessWidget {
  const ProfileOptionTile({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
    this.proximamente = false,
    this.danger = false,
    this.trailingIcon = Icons.chevron_right_rounded,
  });

  final IconData icon;
  final NcAccent accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;
  final bool proximamente;
  final bool danger;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Semantics(
      button: true,
      label: '$title. $subtitle${proximamente ? '. Próximamente' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Opacity(
                opacity: proximamente ? 0.55 : 1,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: accent.ink),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.labelSemiBold(
                                color: danger
                                    ? nc.tomateA.ink
                                    : (proximamente
                                        ? nc.textSecondary
                                        : nc.textPrimary))
                            .copyWith(fontSize: 15)),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.bodySmall(color: nc.textSecondary)),
                  ],
                ),
              ),
              if (proximamente)
                NcStatusPill(label: 'Pronto', accent: nc.oroA)
              else if (badge > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.fill,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('$badge',
                      style: AppTypography.caption(color: accent.onFill)
                          .copyWith(fontWeight: FontWeight.w800)),
                )
              else
                Icon(trailingIcon, color: nc.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
