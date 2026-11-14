import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class EditProfileSection extends StatelessWidget {
  const EditProfileSection({
    super.key,
    required this.titulo,
    required this.children,
    this.subtitulo,
    this.icon,
    this.accent,
  });

  final String titulo;
  final String? subtitulo;
  final IconData? icon;
  final NcAccent? accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return NcCard(
      padding: const EdgeInsets.all(16),
      gradientBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null && accent != null) ...[
                NcAccentIcon(icon: icon!, accent: accent!, size: 30),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(titulo,
                      style:
                          AppTypography.displaySemiBold(color: nc.textPrimary)
                              .copyWith(fontSize: 17)),
                ),
              ),
            ],
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(subtitulo!,
                style: AppTypography.bodySmall(color: nc.textSecondary)),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
