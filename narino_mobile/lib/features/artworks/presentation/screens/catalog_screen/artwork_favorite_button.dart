import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../marketplace/presentation/providers/favorites_provider.dart';
import '../../../domain/artwork_as_favorite.dart';
import '../../../domain/artwork_model.dart';

class ArtworkFavoriteButton extends ConsumerWidget {
  const ArtworkFavoriteButton({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final isFav = ref.watch(favoritesProvider).isFavorite(artwork.id);
    return Semantics(
      button: true,
      toggled: isFav,
      label: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
      excludeSemantics: true,
      child: NcPressable(
        onTap: () => ref
            .read(favoritesProvider.notifier)
            .toggleFavorite(artwork.id, favorito: artwork.toFavorite()),
        pressedScale: 0.85,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.32),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(isFav),
                  size: 20,
                  color: isFav ? nc.magenta : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
