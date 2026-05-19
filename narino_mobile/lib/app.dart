import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auctions/presentation/screens/auctions_screen.dart';
import 'features/auctions/presentation/screens/auction_detail_screen.dart';
import 'features/auctions/presentation/screens/auction_history_screen.dart';
import 'features/auctions/presentation/screens/create_auction_screen.dart';
import 'features/auth/presentation/providers/auth_guard_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/events/presentation/screens/events_screen.dart';
import 'features/events/presentation/screens/event_detail_screen.dart';
import 'features/events/presentation/screens/publish_event_screen.dart';
import 'features/events/presentation/screens/event_notification_preferences_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/marketplace/presentation/screens/marketplace_screen.dart';
import 'features/marketplace/presentation/screens/cart_screen.dart';
import 'features/marketplace/presentation/screens/checkout_screen.dart';
import 'features/marketplace/presentation/screens/favorites_screen.dart';
import 'features/marketplace/presentation/screens/order_detail_screen.dart';
import 'features/marketplace/presentation/screens/payment_result_screen.dart';
import 'features/marketplace/presentation/screens/purchase_history_screen.dart';
import 'features/marketplace/presentation/screens/sales_history_screen.dart';
import 'features/profile/presentation/screens/my_profile_screen.dart';
import 'features/profile/presentation/screens/edit_profile_screen.dart';
import 'features/profile/presentation/screens/artist_public_profile_screen.dart';
import 'features/profile/presentation/screens/portfolio_screen.dart';
import 'features/profile/presentation/screens/following_screen.dart';
import 'features/profile/presentation/screens/change_email_screen.dart';
import 'features/profile/presentation/screens/active_sessions_screen.dart';
import 'features/profile/presentation/screens/delete_account_screen.dart';
import 'features/profile/presentation/screens/artist_stats_screen.dart';
import 'features/artworks/presentation/screens/catalog_screen.dart';
import 'features/artworks/presentation/screens/artwork_detail_screen.dart';
import 'features/artworks/presentation/screens/publish_artwork_screen.dart';
import 'features/ai/presentation/screens/chatbot_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';

const _publicRoutes = ['/login', '/register', '/forgot-password'];

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isAuth = await ref.read(isAuthenticatedProvider.future);
      final isPublic = _publicRoutes.contains(state.matchedLocation);

      if (!isAuth && !isPublic) return '/login';
      if (isAuth && isPublic) return '/home';
      if (isAuth && !isPublic) {
        final isVerified = await ref.read(isEmailVerifiedProvider.future);
        if (!isVerified) {
          final loc = state.matchedLocation;
          final allowedPrefixes = <String>[
            '/home',
            '/catalog',
            '/marketplace',
            '/events',
            '/auctions',
            '/artworks/',
            '/artistas/',
          ];

          final isAllowed = allowedPrefixes.any((p) {
            if (loc == p) return true;
            return loc.startsWith(p);
          });

          if (!isAllowed) return '/catalog';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MainShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/catalog', builder: (_, __) => const CatalogScreen()),
          GoRoute(
            path: '/artworks/publish',
            builder: (_, __) => const PublishArtworkScreen(),
          ),
          GoRoute(
            path: '/artworks/:id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return ArtworkDetailScreen(artworkId: id);
            },
          ),
          GoRoute(
            path: '/artworks/:id/edit',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return PublishArtworkScreen(artworkIdToEdit: id);
            },
          ),
          GoRoute(
            path: '/marketplace',
            builder: (_, __) => const MarketplaceScreen(),
          ),
          GoRoute(
            path: '/marketplace/cart',
            builder: (_, __) => const CartScreen(),
          ),
          GoRoute(
            path: '/marketplace/checkout',
            builder: (_, state) {
              final orderId = state.uri.queryParameters['orderId']!;
              return CheckoutScreen(orderId: orderId);
            },
          ),
          GoRoute(
            path: '/marketplace/payment-result',
            builder: (_, state) {
              final orderId = state.uri.queryParameters['orderId']!;
              final success = state.uri.queryParameters['success'] == 'true';
              return PaymentResultScreen(orderId: orderId, success: success);
            },
          ),
          GoRoute(
            path: '/marketplace/purchases',
            builder: (_, __) => const PurchaseHistoryScreen(),
          ),
          GoRoute(
            path: '/marketplace/sales',
            builder: (_, __) => const SalesHistoryScreen(),
          ),
          GoRoute(
            path: '/marketplace/favorites',
            builder: (_, __) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/marketplace/order/:id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return OrderDetailScreen(orderId: id);
            },
          ),
          GoRoute(
              path: '/auctions', builder: (_, __) => const AuctionsScreen()),
          GoRoute(
            path: '/auctions/new',
            builder: (_, __) => const CreateAuctionScreen(),
          ),
          GoRoute(
            path: '/auctions/history',
            builder: (_, __) => const AuctionHistoryScreen(),
          ),
          GoRoute(
            path: '/auctions/:id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return AuctionDetailScreen(auctionId: id);
            },
          ),
          GoRoute(path: '/events', builder: (_, __) => const EventsScreen()),
          GoRoute(
            path: '/events/new',
            builder: (_, __) => const PublishEventScreen(),
          ),
          GoRoute(
            path: '/events/notification-preferences',
            builder: (_, __) => const EventNotificationPreferencesScreen(),
          ),
          GoRoute(
            path: '/events/:id',
            builder: (context, state) => EventDetailScreen(
              eventId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(path: '/chatbot', builder: (_, __) => const ChatbotScreen()),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
              path: '/profile', builder: (_, __) => const MyProfileScreen()),
          GoRoute(
            path: '/profile/edit',
            builder: (_, __) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/profile/portfolio',
            builder: (_, __) => const PortfolioScreen(),
          ),
          GoRoute(
            path: '/profile/following',
            builder: (_, __) => const FollowingScreen(),
          ),
          GoRoute(
            path: '/profile/change-email',
            builder: (_, __) => const ChangeEmailScreen(),
          ),
          GoRoute(
            path: '/profile/sessions',
            builder: (_, __) => const ActiveSessionsScreen(),
          ),
          GoRoute(
            path: '/profile/delete-account',
            builder: (_, __) => const DeleteAccountScreen(),
          ),
          GoRoute(
            path: '/profile/stats',
            builder: (_, __) => const ArtistStatsScreen(),
          ),
          GoRoute(
            path: '/artistas/:id',
            builder: (context, state) => ArtistPublicProfileScreen(
              artistId: state.pathParameters['id']!,
            ),
          ),
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

class MainShell extends ConsumerStatefulWidget {
  const MainShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  static const _tabs = <_ShellTab>[
    _ShellTab(
      path: '/home',
      label: 'Inicio',
      iconOutlined: Icons.home_outlined,
      iconFilled: Icons.home,
    ),
    _ShellTab(
      path: '/catalog',
      label: 'Catálogo',
      iconOutlined: Icons.grid_view_outlined,
      iconFilled: Icons.grid_view,
    ),
    _ShellTab(
      path: '/marketplace',
      label: 'Tienda',
      iconOutlined: Icons.storefront_outlined,
      iconFilled: Icons.storefront,
    ),
    _ShellTab(
      path: '/auctions',
      label: 'Subastas',
      iconOutlined: Icons.gavel_outlined,
      iconFilled: Icons.gavel,
    ),
    _ShellTab(
      path: '/events',
      label: 'Eventos',
      iconOutlined: Icons.event_outlined,
      iconFilled: Icons.event,
    ),
    _ShellTab(
      path: '/profile',
      label: 'Perfil',
      iconOutlined: Icons.person_outline,
      iconFilled: Icons.person,
    ),
  ];

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int get _currentIndex {
    final idx =
        MainShell._tabs.indexWhere((t) => widget.location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => context.go(MainShell._tabs[index].path),
        selectedItemColor: AppColors.tierraProfunda,
        items: [
          for (final tab in MainShell._tabs)
            BottomNavigationBarItem(
              icon: Icon(tab.iconOutlined),
              activeIcon: Icon(tab.iconFilled),
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
    required this.iconOutlined,
    required this.iconFilled,
  });

  final String path;
  final String label;
  final IconData iconOutlined;
  final IconData iconFilled;
}
