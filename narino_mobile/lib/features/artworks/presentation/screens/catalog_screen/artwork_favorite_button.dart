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
    void toggle() => ref
        .read(favoritesProvider.notifier)
        .toggleFavorite(artwork.id, favorito: artwork.toFavorite());

    return Semantics(
      // Nodo propio: si no, TalkBack lo funde con la tarjeta y el doble toque
      // abre la obra en vez de marcar el favorito (MO-ACC-01/02).
      container: true,
      button: true,
      toggled: isFav,
      label: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
      onTap: toggle,
      excludeSemantics: true,
      child: NcPressable(
        onTap: toggle,
        pressedScale: 0.85,
        child: NcTapTarget(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              // Sin desenfoque: un BackdropFilter por tarjeta era costoso
              // al hacer scroll (MO-LOAD-01). Más opaco para leerse igual.
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(isFav),
                size: 20,
                color: isFav ? nc.magenta : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
