import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auctions/presentation/screens/auctions_screen.dart';
import 'features/auth/presentation/providers/auth_guard_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/events/presentation/screens/events_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/marketplace/presentation/screens/marketplace_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/artworks/presentation/screens/catalog_screen.dart';
import 'features/artworks/presentation/screens/artwork_detail_screen.dart';
import 'features/artworks/presentation/screens/publish_artwork_screen.dart';

const _publicRoutes = ['/login', '/register'];

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isAuth = await ref.read(isAuthenticatedProvider.future);
      final isPublic = _publicRoutes.contains(state.matchedLocation);

      if (!isAuth && !isPublic) return '/login';
      if (isAuth && isPublic) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/artworks/publish',
        builder: (_, __) => const PublishArtworkScreen(),
      ),
      GoRoute(
        path: '/artworks/:id/edit',
        builder: (_, state) => PublishArtworkScreen(
          artworkId: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/artworks/:id',
        builder: (_, state) => ArtworkDetailScreen(
          artworkId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MainShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/catalog', builder: (_, __) => const CatalogScreen()),
          GoRoute(
            path: '/marketplace',
            builder: (_, __) => const MarketplaceScreen(),
          ),
          GoRoute(path: '/auctions', builder: (_, __) => const AuctionsScreen()),
          GoRoute(path: '/events', builder: (_, __) => const EventsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});

class NarinoCulturaApp extends ConsumerWidget {
  const NarinoCulturaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  static const _tabs = <_ShellTab>[
    _ShellTab(path: '/home', label: 'Inicio', icon: Icons.home_outlined),
    _ShellTab(
      path: '/catalog',
      label: 'Catálogo',
      icon: Icons.grid_view_outlined,
    ),
    _ShellTab(
      path: '/marketplace',
      label: 'Tienda',
      icon: Icons.storefront_outlined,
    ),
    _ShellTab(path: '/auctions', label: 'Subastas', icon: Icons.gavel_outlined),
    _ShellTab(
      path: '/events',
      label: 'Eventos',
      icon: Icons.event_outlined,
    ),
    _ShellTab(path: '/profile', label: 'Perfil', icon: Icons.person_outline),
  ];

  int get _currentIndex {
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => context.go(_tabs[index].path),
        items: [
          for (final tab in _tabs)
            BottomNavigationBarItem(
              icon: Icon(tab.icon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab({
    required this.path,
    required this.label,
    required this.icon,
  });

  final String path;
  final String label;
  final IconData icon;
}
