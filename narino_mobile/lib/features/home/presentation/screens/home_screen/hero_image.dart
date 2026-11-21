import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../artworks/domain/artwork_model.dart';
import '../home_screen.dart';
import 'featured_strip.dart';

class HeroImage extends ConsumerWidget {
  const HeroImage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final featured =
        ref.watch(homeFeaturedArtworksProvider(kHomeFeaturedLimit)).valueOrNull;
    final ArtworkModel? obra =
        featured?.where((a) => a.imagenes.isNotEmpty).firstOrNull;

    final placeholder = Center(
      child: Text(
        '[ CARNAVAL DE NEGROS Y BLANCOS ]',
        textAlign: TextAlign.center,
        style: AppTypography.caption(color: nc.textSecondary)
            .copyWith(fontSize: 12, letterSpacing: 1.2),
      ),
    );

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: nc.itemFill,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: nc.border),
          boxShadow: nc.shadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: obra == null
            ? placeholder
            : GestureDetector(
                onTap: () => context.push('/artworks/${obra.id}'),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: obra.imagenes.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => placeholder,
                      errorWidget: (_, __, ___) => placeholder,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC000000)],
                          stops: [0.5, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OBRA DESTACADA',
                            style: AppTypography.caption(
                                color: AppColors.oroTierra),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            obra.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.displaySemiBold(
                                color: Colors.white),
                          ),
                          Text(
                            obra.artistaNombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTypography.bodySmall(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
