import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../musicians/presentation/providers/musician_provider.dart';
import '../../domain/profile_model.dart';
import '../providers/profile_provider.dart';
import '../widgets/disciplinas.dart';

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
            _Tarjeta(
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
              const _Titulo('Mi espacio web'),
              _Grupo(children: [
                for (final e in links)
                  _Opcion(
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
              const _Titulo('Mi contenido'),
              _Grupo(children: [
                if (!esMusico)
                  _Opcion(
                    icon: Icons.palette_outlined,
                    accent: nc.catalogo,
                    title: 'Mis obras',
                    subtitle: 'Publica, edita y subasta tus obras',
                    onTap: () => context.push('/profile/my-artworks'),
                  ),
                _Opcion(
                  icon: Icons.collections_outlined,
                  accent: nc.naranjaA,
                  title: 'Mi portafolio',
                  subtitle: 'Fotos y videos de tu proceso',
                  proximamente: _kProximamente.contains('portafolio'),
                  onTap: () => _kProximamente.contains('portafolio')
                      ? _proximamente('El portafolio')
                      : context.push('/profile/portfolio'),
                ),
                _Opcion(
                  icon: Icons.trending_up_rounded,
                  accent: nc.oroA,
                  title: 'Mis ventas',
                  subtitle: 'Lo que has vendido y cuánto has ganado',
                  onTap: () => context.push('/marketplace/sales'),
                ),
                if (profile?.disciplina.trim().isNotEmpty == true)
                  _Opcion(
                    icon: Icons.insights_rounded,
                    accent: nc.azulA,
                    title: 'Mis estadísticas',
                    subtitle: 'Visitas, seguidores e ingresos',
                    onTap: () => context.push('/profile/stats'),
                  ),
              ]),
              if (esMusico) ...[
                const _Titulo('Mi música'),
                const _Grupo(children: [_OpcionMusico()]),
              ],
            ],
            const _Titulo('Compras y actividad'),
            _Grupo(children: [
              _Opcion(
                icon: Icons.shopping_bag_outlined,
                accent: nc.tienda,
                title: 'Mis compras',
                subtitle: 'Órdenes, pagos y comprobantes',
                onTap: () => context.push('/marketplace/purchases'),
              ),
              _Opcion(
                icon: Icons.favorite_border_rounded,
                accent: nc.magentaA,
                title: 'Mis favoritos',
                subtitle: 'Obras que guardaste',
                badge: favs,
                onTap: () => context.push('/marketplace/favorites'),
              ),
              _Opcion(
                icon: Icons.people_outline_rounded,
                accent: nc.azulA,
                title: 'Siguiendo',
                subtitle: 'Artistas y músicos que sigues',
                onTap: () => context.push('/profile/following'),
              ),
              _Opcion(
                icon: Icons.gavel_rounded,
                accent: nc.subastas,
                title: 'Mis subastas',
                subtitle: 'Pujas y subastas que abriste',
                onTap: () => context.push('/auctions/history'),
              ),
            ]),
            const _Titulo('Configuración'),
            _Grupo(children: [
              _Opcion(
                icon: Icons.notifications_none_rounded,
                accent: nc.eventos,
                title: 'Avisos de eventos',
                subtitle: 'Elige qué eventos te interesan',
                onTap: () => context.push('/events/notification-preferences'),
              ),
              const _TemaOpcion(),
              _Opcion(
                icon: Icons.shield_outlined,
                accent: nc.successA,
                title: 'Privacidad',
                subtitle: 'Cómo cuidamos tus datos',
                onTap: () => context.push('/profile/privacy'),
              ),
              _Opcion(
                icon: Icons.alternate_email_rounded,
                accent: nc.azulA,
                title: 'Cambiar correo',
                subtitle: 'Actualiza tu correo electrónico',
                proximamente: _kProximamente.contains('correo'),
                onTap: () => _kProximamente.contains('correo')
                    ? _proximamente('Cambiar el correo')
                    : context.push('/profile/change-email'),
              ),
              _Opcion(
                icon: Icons.devices_outlined,
                accent: nc.azulA,
                title: 'Sesiones activas',
                subtitle: 'Dispositivos con tu cuenta abierta',
                proximamente: _kProximamente.contains('sesiones'),
                onTap: () => _kProximamente.contains('sesiones')
                    ? _proximamente('Ver las sesiones activas')
                    : context.push('/profile/sessions'),
              ),
              _Opcion(
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

// ─── Tarjeta principal ──────────────────────────────────────────────────────

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.profile,
    required this.role,
    required this.favs,
    required this.photoVersion,
  });

  final ProfileModel? profile;
  final String? role;
  final int favs;
  final int photoVersion;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final p = profile;
    final nombre = (p?.nombreArtistico.trim().isNotEmpty ?? false)
        ? p!.nombreArtistico
        : 'Tu perfil';
    final foto = p?.fotoUrl;
    final (String rolLabel, NcAccent rolAccent) = switch (role) {
      'artista' => ('Artista', nc.catalogo),
      'gestor' => ('Gestor cultural', nc.eventos),
      'admin' => ('Administración', nc.azulA),
      'comprador' => ('Amante del arte', nc.tienda),
      _ => ('Visitante', nc.azulA),
    };
    final esArtista = role == 'artista';

    return NcCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                ...nc.carnavalGradient.colors,
                nc.carnavalGradient.colors.first,
              ]),
            ),
            child: CircleAvatar(
              key: ValueKey('avatar-$photoVersion'),
              radius: 44,
              backgroundColor: nc.bgCard,
              backgroundImage: (foto != null && foto.isNotEmpty)
                  // La key fuerza a redibujar tras cambiar la foto; no se
                  // altera la URL (podría ser firmada).
                  ? CachedNetworkImageProvider(foto)
                  : null,
              child: (foto == null || foto.isEmpty)
                  ? Text(
                      nombre.characters.first.toUpperCase(),
                      style: AppTypography.displayBold(color: rolAccent.ink)
                          .copyWith(fontSize: 34),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(nombre,
                    textAlign: TextAlign.center,
                    style: AppTypography.displayBold(color: nc.textPrimary)),
              ),
              if (p?.esVerificado == true) ...[
                const SizedBox(width: 6),
                Icon(Icons.verified_rounded, size: 20, color: nc.azul),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              NcStatusPill(label: rolLabel, accent: rolAccent, filled: true),
              if (p?.disciplina.trim().isNotEmpty == true)
                NcStatusPill(label: p!.disciplina, accent: rolAccent),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Dato(
                valor: '${p?.seguidores ?? 0}',
                label: 'Seguidores',
              ),
              _Dato(
                valor: '${p?.totalObras ?? 0}',
                label: 'Obras',
                onTap: esArtista
                    ? () => context.push('/profile/my-artworks')
                    : null,
              ),
              _Dato(
                valor: '$favs',
                label: 'Favoritos',
                onTap: () => context.push('/marketplace/favorites'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: NcSecondaryButton(
                  label: 'Editar perfil',
                  icon: Icons.edit_outlined,
                  onPressed: () => context.push('/profile/edit'),
                ),
              ),
              if (esArtista && (p?.id.isNotEmpty ?? false)) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: NcSecondaryButton(
                    label: 'Ver público',
                    icon: Icons.visibility_outlined,
                    onPressed: () => context.push('/artistas/${p!.id}'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.valor, required this.label, this.onTap});

  final String valor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Expanded(
      child: NcPressable(
        onTap: onTap,
        semanticLabel: '$valor $label',
        child: Column(
          children: [
            Text(valor,
                style: AppTypography.displaySemiBold(color: nc.textPrimary)),
            Text(label,
                style: AppTypography.bodySmall(color: nc.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Secciones ──────────────────────────────────────────────────────────────

class _Titulo extends StatelessWidget {
  const _Titulo(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
      child: Text(text.toUpperCase(),
          style: AppTypography.caption(color: context.nc.textSecondary)
              .copyWith(letterSpacing: 0.9, fontWeight: FontWeight.w700)),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return NcCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      gradientBorder: false,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 66, color: nc.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
    this.proximamente = false,
    this.danger = false,
    this.trailingIcon = Icons.chevron_right_rounded,
  });

  final IconData icon;
  final NcAccent accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;
  final bool proximamente;
  final bool danger;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Semantics(
      button: true,
      label: '$title. $subtitle${proximamente ? '. Próximamente' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Opacity(
                opacity: proximamente ? 0.55 : 1,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: accent.ink),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.labelSemiBold(
                                color: danger
                                    ? nc.tomateA.ink
                                    : (proximamente
                                        ? nc.textSecondary
                                        : nc.textPrimary))
                            .copyWith(fontSize: 15)),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.bodySmall(color: nc.textSecondary)),
                  ],
                ),
              ),
              if (proximamente)
                NcStatusPill(label: 'Pronto', accent: nc.oroA)
              else if (badge > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.fill,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('$badge',
                      style: AppTypography.caption(color: accent.onFill)
                          .copyWith(fontWeight: FontWeight.w800)),
                )
              else
                Icon(trailingIcon, color: nc.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionMusico extends ConsumerWidget {
  const _OpcionMusico();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final slug = ref.watch(myMusicianSlugProvider);
    return slug.when(
      loading: () => _Opcion(
        icon: Icons.music_note_rounded,
        accent: nc.musica,
        title: 'Mi perfil de músico',
        subtitle: 'Cargando…',
        onTap: () {},
      ),
      error: (_, __) => _Opcion(
        icon: Icons.music_note_rounded,
        accent: nc.musica,
        title: 'Mi perfil de músico',
        subtitle: 'Toca para reintentar',
        onTap: () => ref.invalidate(myMusicianSlugProvider),
      ),
      data: (s) => s == null
          ? _Opcion(
              icon: Icons.library_add_outlined,
              accent: nc.musica,
              title: 'Completar perfil musical',
              subtitle: 'Agrega tu formato y géneros',
              onTap: () => context.push('/artistic-profile'),
            )
          : _Opcion(
              icon: Icons.music_note_rounded,
              accent: nc.musica,
              title: 'Mi perfil de músico',
              subtitle: 'Obras, reseñas y seguidores',
              onTap: () => context.push('/musicians/$s'),
            ),
    );
  }
}

/// Selector de tema: Sistema / Claro / Oscuro.
class _TemaOpcion extends ConsumerWidget {
  const _TemaOpcion();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final mode = ref.watch(themeModeProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: nc.magentaA.tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.contrast_rounded, size: 20, color: nc.magentaA.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Apariencia',
                style: AppTypography.labelSemiBold(color: nc.textPrimary)
                    .copyWith(fontSize: 15)),
          ),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              selectedBackgroundColor: nc.azul,
              selectedForegroundColor: nc.onAzul,
              side: BorderSide(color: nc.border),
            ),
            segments: const [
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.phone_android_rounded, size: 18),
                  tooltip: 'Como el sistema'),
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined, size: 18),
                  tooltip: 'Claro'),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined, size: 18),
                  tooltip: 'Oscuro'),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).setMode(s.first),
          ),
        ],
      ),
    );
  }
}
