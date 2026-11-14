import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../marketplace/presentation/providers/favorites_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/disciplinas.dart';
import 'my_profile_screen/musician_profile_option.dart';
import 'my_profile_screen/profile_option_group.dart';
import 'my_profile_screen/profile_option_tile.dart';
import 'my_profile_screen/profile_section_title.dart';
import 'my_profile_screen/profile_summary_card.dart';
import 'my_profile_screen/theme_mode_option.dart';

/// Funciones cuyo endpoint aún no existe en el backend (ver MAPA_TRABAJO #7, #8).
const _kProximamente = {'portafolio', 'correo', 'sesiones'};

/// Perfil propio (acento: serpentina completa).
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myProfileProvider.notifier).loadMyProfile();
      ref.read(favoritesProvider.notifier).loadFavorites();
    });
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Podrás volver a entrar cuando quieras con tu '
            'correo y contraseña.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tomate,
              foregroundColor: Colors.black,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(authProvider.notifier).logout();
    } catch (_) {}
    ref.read(myProfileProvider.notifier).reset();
    if (mounted) context.go('/login');
  }

  void _proximamente(String que) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
        content: Text('$que estará disponible muy pronto. Estamos terminando '
            'esta función en el servidor.')));

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final state = ref.watch(myProfileProvider);
    final favs = ref.watch(favoritesProvider).favorites.length;
    final role = ref.watch(currentUserRoleProvider).valueOrNull;
    final esArtista = role == 'artista' || role == 'admin';
    final profile = state.profile;
    final esMusico = esDisciplinaMusical(profile?.disciplina);
    final top = MediaQuery.paddingOf(context).top + NcGlassHeader.contentHeight;
    final brightness = Theme.of(context).brightness;

    if (state.isLoading && profile == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final links = profile?.redesSociales.entries
            .where((e) => e.value.trim().isNotEmpty)
            .toList() ??
        const [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: NcGlassHeader(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TU ESPACIO',
                style: AppTypography.caption(color: nc.oroA.ink)
                    .copyWith(letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text('Perfil',
                style: AppTypography.displaySemiBold(color: nc.textPrimary)),
          ],
        ),
        actions: [
          NcIconButton(
            icon: brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            tooltip: brightness == Brightness.dark
                ? 'Cambiar a modo claro'
                : 'Cambiar a modo oscuro',
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggle(brightness),
          ),
        ],
      ),
      body: RefreshIndicator(
        edgeOffset: top,
        onRefresh: () => ref.read(myProfileProvider.notifier).loadMyProfile(),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, top + 16, 16, 32),
          children: [
            ProfileSummaryCard(
              profile: profile,
              role: role,
              favs: favs,
              photoVersion: state.photoVersion,
            ),
            if (profile?.esVerificado == false) ...[
              const SizedBox(height: 12),
              NcBanner(
                accent: nc.oroA,
                icon: Icons.mark_email_unread_outlined,
                message: 'Tu correo aún no está verificado. Revisa tu bandeja '
                    'para tener acceso completo.',
              ),
            ],
            if (links.isNotEmpty) ...[
              const ProfileSectionTitle('Mi espacio web'),
              ProfileOptionGroup(children: [
                for (final e in links)
                  ProfileOptionTile(
                    icon: _iconoRed(e.key),
                    accent: nc.azulA,
                    title: _nombreRed(e.key),
                    subtitle: e.value.replaceFirst(RegExp(r'^https?://'), ''),
                    trailingIcon: Icons.open_in_new_rounded,
                    onTap: () => launchUrl(Uri.parse(e.value),
                        mode: LaunchMode.externalApplication),
                  ),
              ]),
            ],
            if (esArtista) ...[
              const ProfileSectionTitle('Mi contenido'),
              ProfileOptionGroup(children: [
                if (!esMusico)
                  ProfileOptionTile(
                    icon: Icons.palette_outlined,
                    accent: nc.catalogo,
                    title: 'Mis obras',
                    subtitle: 'Publica, edita y subasta tus obras',
                    onTap: () => context.push('/profile/my-artworks'),
                  ),
                ProfileOptionTile(
                  icon: Icons.collections_outlined,
                  accent: nc.naranjaA,
                  title: 'Mi portafolio',
                  subtitle: 'Fotos y videos de tu proceso',
                  proximamente: _kProximamente.contains('portafolio'),
                  onTap: () => _kProximamente.contains('portafolio')
                      ? _proximamente('El portafolio')
                      : context.push('/profile/portfolio'),
                ),
                ProfileOptionTile(
                  icon: Icons.trending_up_rounded,
                  accent: nc.oroA,
                  title: 'Mis ventas',
                  subtitle: 'Lo que has vendido y cuánto has ganado',
                  onTap: () => context.push('/marketplace/sales'),
                ),
                if (profile?.disciplina.trim().isNotEmpty == true)
                  ProfileOptionTile(
                    icon: Icons.insights_rounded,
                    accent: nc.azulA,
                    title: 'Mis estadísticas',
                    subtitle: 'Visitas, seguidores e ingresos',
                    onTap: () => context.push('/profile/stats'),
                  ),
              ]),
              if (esMusico) ...[
                const ProfileSectionTitle('Mi música'),
                const ProfileOptionGroup(children: [MusicianProfileOption()]),
              ],
            ],
            const ProfileSectionTitle('Compras y actividad'),
            ProfileOptionGroup(children: [
              ProfileOptionTile(
                icon: Icons.shopping_bag_outlined,
                accent: nc.tienda,
                title: 'Mis compras',
                subtitle: 'Órdenes, pagos y comprobantes',
                onTap: () => context.push('/marketplace/purchases'),
              ),
              ProfileOptionTile(
                icon: Icons.favorite_border_rounded,
                accent: nc.magentaA,
                title: 'Mis favoritos',
                subtitle: 'Obras que guardaste',
                badge: favs,
                onTap: () => context.push('/marketplace/favorites'),
              ),
              ProfileOptionTile(
                icon: Icons.people_outline_rounded,
                accent: nc.azulA,
                title: 'Siguiendo',
                subtitle: 'Artistas y músicos que sigues',
                onTap: () => context.push('/profile/following'),
              ),
              ProfileOptionTile(
                icon: Icons.gavel_rounded,
                accent: nc.subastas,
                title: 'Mis subastas',
                subtitle: 'Pujas y subastas que abriste',
                onTap: () => context.push('/auctions/history'),
              ),
            ]),
            const ProfileSectionTitle('Configuración'),
            ProfileOptionGroup(children: [
              ProfileOptionTile(
                icon: Icons.notifications_none_rounded,
                accent: nc.eventos,
                title: 'Avisos de eventos',
                subtitle: 'Elige qué eventos te interesan',
                onTap: () => context.push('/events/notification-preferences'),
              ),
              const ThemeModeOption(),
              ProfileOptionTile(
                icon: Icons.shield_outlined,
                accent: nc.successA,
                title: 'Privacidad',
                subtitle: 'Cómo cuidamos tus datos',
                onTap: () => context.push('/profile/privacy'),
              ),
              ProfileOptionTile(
                icon: Icons.key_rounded,
                accent: nc.oroA,
                title: 'Cambiar contraseña',
                subtitle: 'Usa una clave nueva y segura',
                onTap: () => context.push('/profile/password'),
              ),
              ProfileOptionTile(
                icon: Icons.alternate_email_rounded,
                accent: nc.azulA,
                title: 'Cambiar correo',
                subtitle: 'Actualiza tu correo electrónico',
                proximamente: _kProximamente.contains('correo'),
                onTap: () => _kProximamente.contains('correo')
                    ? _proximamente('Cambiar el correo')
                    : context.push('/profile/change-email'),
              ),
              ProfileOptionTile(
                icon: Icons.devices_outlined,
                accent: nc.azulA,
                title: 'Sesiones activas',
                subtitle: 'Dispositivos con tu cuenta abierta',
                proximamente: _kProximamente.contains('sesiones'),
                onTap: () => _kProximamente.contains('sesiones')
                    ? _proximamente('Ver las sesiones activas')
                    : context.push('/profile/sessions'),
              ),
              ProfileOptionTile(
                icon: Icons.delete_outline_rounded,
                accent: nc.tomateA,
                title: 'Eliminar cuenta',
                subtitle: 'Borra tu cuenta de forma permanente',
                danger: true,
                onTap: () => context.push('/profile/delete-account'),
              ),
            ]),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: nc.tomateA.ink,
                side: BorderSide(color: nc.tomateA.fill.withValues(alpha: 0.6)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
            ),
            const SizedBox(height: 16),
            const Center(child: NcSerpentina(width: 48)),
            const SizedBox(height: 8),
            Center(
              child: Text('Nariño Cultura · hecho con amor en Nariño',
                  style: AppTypography.bodySmall(color: nc.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconoRed(String k) => switch (k) {
        'instagram' => Icons.camera_alt_outlined,
        'facebook' => Icons.facebook_rounded,
        'tiktok' => Icons.music_video_outlined,
        _ => Icons.language_rounded,
      };

  static String _nombreRed(String k) => switch (k) {
        'instagram' => 'Instagram',
        'facebook' => 'Facebook',
        'tiktok' => 'TikTok',
        'website' => 'Sitio web',
        _ => k,
      };
}
