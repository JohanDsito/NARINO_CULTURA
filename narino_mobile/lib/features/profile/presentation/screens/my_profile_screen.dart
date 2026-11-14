import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../../shared/widgets/dialogs/confirmar_accion.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../marketplace/presentation/providers/favorites_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/disciplinas.dart';
import 'my_profile_screen/profile_activity_section.dart';
import 'my_profile_screen/profile_content_section.dart';
import 'my_profile_screen/profile_logout_footer.dart';
import 'my_profile_screen/profile_settings_section.dart';
import 'my_profile_screen/profile_summary_card.dart';
import 'my_profile_screen/profile_web_links_section.dart';

/// Perfil propio (acento: serpentina completa). Arma las secciones de
/// `my_profile_screen/`; aquí solo se cargan los datos y se cierra sesión.
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
    final ok = await confirmarAccion(
      context,
      titulo: '¿Cerrar sesión?',
      mensaje: 'Podrás volver a entrar cuando quieras con tu correo y '
          'contraseña.',
      confirmar: 'Cerrar sesión',
      peligro: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(authProvider.notifier).logout();
    } catch (_) {}
    ref.read(myProfileProvider.notifier).reset();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final state = ref.watch(myProfileProvider);
    final favs = ref.watch(favoritesProvider).favorites.length;
    final role = ref.watch(currentUserRoleProvider).valueOrNull;
    final esArtista = role == 'artista' || role == 'admin';
    final profile = state.profile;
    final top = MediaQuery.paddingOf(context).top + NcGlassHeader.contentHeight;

    if (state.isLoading && profile == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final links = profile?.redesSociales.entries
            .where((e) => e.value.trim().isNotEmpty)
            .toList() ??
        const <MapEntry<String, String>>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _header(context),
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
            if (links.isNotEmpty) ProfileWebLinksSection(links: links),
            if (esArtista)
              ProfileContentSection(
                profile: profile,
                esMusico: esDisciplinaMusical(profile?.disciplina),
              ),
            ProfileActivitySection(favoritos: favs),
            const ProfileSettingsSection(),
            ProfileLogoutFooter(onLogout: _logout),
          ],
        ),
      ),
    );
  }

  NcGlassHeader _header(BuildContext context) {
    final nc = context.nc;
    final brightness = Theme.of(context).brightness;
    final oscuro = brightness == Brightness.dark;
    return NcGlassHeader(
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
          icon: oscuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          tooltip: oscuro ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
          onPressed: () =>
              ref.read(themeModeProvider.notifier).toggle(brightness),
        ),
      ],
    );
  }
}
