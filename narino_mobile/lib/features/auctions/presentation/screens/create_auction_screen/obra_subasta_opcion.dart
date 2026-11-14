import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../artworks/domain/artwork_model.dart';
import '../../widgets/subasta_ui.dart';

class ObraSubastaOpcion extends StatelessWidget {
  const ObraSubastaOpcion({
    super.key,
    required this.obra,
    required this.selected,
    required this.onTap,
  });

  final ArtworkModel obra;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final img = obra.imagenes.isNotEmpty ? obra.imagenes.first : null;
    return Semantics(
      selected: selected,
      button: true,
      label: obra.titulo,
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.96,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 132,
          decoration: BoxDecoration(
            color: nc.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? nc.subastas.fill : nc.border,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    img == null
                        ? const SubastaImage(url: null)
                        : CachedNetworkImage(imageUrl: img, fit: BoxFit.cover),
                    if (selected)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              color: nc.subastas.fill, shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded,
                              size: 16, color: nc.subastas.onFill),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(obra.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium(color: nc.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
