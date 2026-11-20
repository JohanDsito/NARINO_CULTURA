import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class FollowArtistButton extends StatelessWidget {
  const FollowArtistButton({
    super.key,
    required this.sigue,
    required this.loading,
    required this.onTap,
  });

  final bool sigue;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = nc.catalogo;
    return Semantics(
      button: true,
      toggled: sigue,
      label: sigue ? 'Dejar de seguir' : 'Seguir',
      onTap: loading ? null : onTap,
      excludeSemantics: true,
      child: NcPressable(
        onTap: loading ? null : onTap,
        pressedScale: 0.92,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: sigue ? Colors.transparent : a.fill,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: sigue ? nc.border : a.fill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sigue ? Icons.check_rounded : Icons.add_rounded,
                  size: 18, color: sigue ? nc.textPrimary : a.onFill),
              const SizedBox(width: 4),
              Text(sigue ? 'Siguiendo' : 'Seguir',
                  style: AppTypography.labelMedium(
                          color: sigue ? nc.textPrimary : a.onFill)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
