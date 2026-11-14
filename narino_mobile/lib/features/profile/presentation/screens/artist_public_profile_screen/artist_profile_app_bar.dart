import 'package:flutter/material.dart';

import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

/// Cabecera del perfil público: serpentina suavizada y botón de volver.
class ArtistProfileAppBar extends StatelessWidget {
  const ArtistProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: nc.bg,
      surfaceTintColor: Colors.transparent,
      shape: const Border(),
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: GlassCircleButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Serpentina del Carnaval, suavizada para no competir con el
            // contenido.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    for (final c in nc.carnavalGradient.colors)
                      c.withValues(alpha: nc.isDark ? 0.45 : 0.28),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              child: Container(
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: nc.bg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: const NcSerpentina(width: 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
