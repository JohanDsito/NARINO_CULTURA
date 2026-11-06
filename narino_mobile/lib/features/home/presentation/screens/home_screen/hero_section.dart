import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/providers/user_role_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../artworks/domain/artwork_model.dart';
import '../home_screen.dart';
import 'featured_strip.dart';

/// Hero: kicker en oro, título con degradado (oscuro), texto, dos acciones e
/// imagen destacada (la obra más vista).
class HeroSection extends ConsumerWidget {
  const HeroSection({super.key, required this.onSecondaryFallback});

  /// Acción secundaria para quien no publica (lleva a la agenda).
  final VoidCallback onSecondaryFallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final role = ref.watch(currentUserRoleProvider).valueOrNull ?? '';

    final (String label, VoidCallback onTap) secondary = switch (role) {
      'artista' => ('Publicar una obra', () => context.push('/artworks/publish')),
      'gestor' || 'admin' =>
        ('Publicar un evento', () => context.push('/events/new')),
      _ => ('Ver la agenda cultural', onSecondaryFallback),
    };

    final title = Text(
      'La cultura viva de Nariño en un solo ecosistema',
      style: AppTypography.displayBlack(color: nc.textPrimary)
          .copyWith(fontSize: 36, height: 1.06),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('El alma del Carnaval', style: AppTypography.kicker(color: nc.oroA.ink)),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: nc.isDark
                ? ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, AppColors.azulNeon],
                    ).createShader(r),
                    child: title,
                  )
                : title,
          ),
          const SizedBox(height: 16),
          Text(
            'Conecta con artesanos, descubre el lente de nuestros fotógrafos, '
            'adquiere obras maestras y vibra con los músicos locales.',
            style: AppTypography.bodyLarge(color: nc.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/catalog'),
              child: const Text('Explorar obras'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: secondary.$2,
              child: Text(secondary.$1),
            ),
          ),
          const SizedBox(height: 28),
          const _HeroImage(),
        ],
      ),
    );
  }
}

class _HeroImage extends ConsumerWidget {
  const _HeroImage();

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
