import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../artworks/domain/artwork_model.dart';
import '../../../../marketplace/presentation/widgets/tienda_ui.dart';
import 'formato_miles.dart';

class TopArtworkRow extends StatelessWidget {
  const TopArtworkRow({
    super.key,
    required this.puesto,
    required this.obra,
    required this.fraccion,
  });

  final int puesto;
  final ArtworkModel obra;
  final double fraccion;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final medalla = switch (puesto) {
      1 => nc.oroA,
      2 => nc.naranjaA,
      3 => nc.catalogo,
      _ => nc.azulA,
    };
    return Semantics(
      button: true,
      label: 'Puesto $puesto: ${obra.titulo}, ${obra.viewsCount} vistas',
      excludeSemantics: true,
      child: NcPressable(
        onTap: () => context.push('/artworks/${obra.id}'),
        pressedScale: 0.98,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: nc.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: nc.border),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ObraThumb(
                      url:
                          obra.imagenes.isNotEmpty ? obra.imagenes.first : null,
                      size: 56),
                  Positioned(
                    left: -4,
                    top: -4,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: medalla.fill,
                        shape: BoxShape.circle,
                        border: Border.all(color: nc.bgCard, width: 2),
                      ),
                      child: Text('$puesto',
                          style:
                              AppTypography.labelMedium(color: medalla.onFill)
                                  .copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(obra.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.labelSemiBold(color: nc.textPrimary)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: fraccion.clamp(0.04, 1.0),
                        minHeight: 6,
                        backgroundColor: nc.itemFill,
                        color: medalla.fill,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                        '${formatMiles(obra.viewsCount)} '
                        '${obra.viewsCount == 1 ? 'vista' : 'vistas'}',
                        style:
                            AppTypography.bodySmall(color: nc.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: nc.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
