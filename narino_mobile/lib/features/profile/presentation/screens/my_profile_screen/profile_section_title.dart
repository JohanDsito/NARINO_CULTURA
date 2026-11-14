import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

// ─── Secciones ──────────────────────────────────────────────────────────────

class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
      child: Text(text.toUpperCase(),
          style: AppTypography.caption(color: context.nc.textSecondary)
              .copyWith(letterSpacing: 0.9, fontWeight: FontWeight.w700)),
    );
  }
}
