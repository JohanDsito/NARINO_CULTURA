import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/favorite_model.dart';
import '../../widgets/tienda_ui.dart';

class FavoriteCard extends StatelessWidget {
  const FavoriteCard({super.key, required this.fav, required this.onRemove});

  final FavoriteModel fav;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final (String? badge, NcAccent? accent) = fav.isVendida
        ? ('Vendida', nc.tomateA)
        : fav.isEnSubasta
            ? ('En subasta', nc.subastas)
            : (null, null);
    final url = fav.imagenUrl;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [nc.magentaA.tint, nc.naranjaA.tint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child:
          Center(child: Icon(Icons.palette_outlined, color: nc.catalogo.ink)),
    );

    return NcPressable(
      onTap: () => context.push('/artworks/${fav.obraId}'),
      pressedScale: 0.97,
      semanticLabel: fav.obraTitulo,
      child: Container(
        decoration: BoxDecoration(
          color: nc.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: nc.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url != null && url.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => fallback,
                      errorWidget: (_, __, ___) => fallback,
                    )
                  else
                    fallback,
                  if (badge != null)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: NcStatusPill(
                          label: badge, accent: accent!, filled: true),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Semantics(
                      button: true,
                      label: 'Quitar de favoritos',
                      excludeSemantics: true,
                      child: NcPressable(
                        onTap: onRemove,
                        pressedScale: 0.85,
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 40,
                              height: 40,
                              color: Colors.black.withValues(alpha: 0.32),
                              child: Icon(Icons.favorite_rounded,
                                  size: 20, color: nc.magenta),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fav.obraTitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSemiBold(color: nc.textPrimary)
                          .copyWith(fontSize: 14)),
                  if (fav.artistaNombre.isNotEmpty)
                    Text(fav.artistaNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.bodySmall(color: nc.textSecondary)),
                  const SizedBox(height: 6),
                  Text(
                    fav.precio != null && fav.precio! > 0
                        ? formatCOP(fav.precio!)
                        : 'En exhibición',
                    style: fav.precio != null && fav.precio! > 0
                        ? AppTypography.labelSemiBold(color: nc.tienda.ink)
                            .copyWith(fontWeight: FontWeight.w800, fontSize: 14)
                        : AppTypography.bodySmall(color: nc.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
