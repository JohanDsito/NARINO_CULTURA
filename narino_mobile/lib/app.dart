import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/network/session_expiry.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/session_reset.dart';

class NarinoCulturaApp extends ConsumerStatefulWidget {
  const NarinoCulturaApp({super.key});

  @override
  ConsumerState<NarinoCulturaApp> createState() => _NarinoCulturaAppState();
}

class _NarinoCulturaAppState extends ConsumerState<NarinoCulturaApp> {
  @override
  void initState() {
    super.initState();
    SessionExpiry.notifier.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    SessionExpiry.notifier.removeListener(_onSessionExpired);
    super.dispose();
  }

  /// La sesión expiró: que no queden en pantalla datos de esa persona.
  void _onSessionExpired() => resetUserSession(ref.invalidate);

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
