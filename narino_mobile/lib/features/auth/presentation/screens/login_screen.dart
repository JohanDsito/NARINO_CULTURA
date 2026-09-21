import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';
import 'login_screen/auth_link.dart';
import 'login_screen/error_banner.dart';
import 'login_screen/login_hero.dart';
import 'login_screen/submit_button.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  late final ProviderSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = ref.listenManual<AuthState>(authProvider, (prev, next) {
      if (!mounted) return;
      if (next.status == AuthStatus.authenticated) {
        if (next.isArtista) {
          context.go('/artistic-profile');
        } else {
          context.go('/home');
        }
      }
    });
  }

  @override
  void dispose() {
    _authSub.close();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _clearError() => ref.read(authProvider.notifier).clearError();

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
      return 'Correo inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero ──────────────────────────────────────────────────────
            const Expanded(
              flex: 2,
              child: LoginHero(),
            ),

            // ── Formulario ────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: bg,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Iniciar sesión',
                              style: AppTypography.displaySemiBold(
                                  color: textPrimary),
                            ),
                            const SizedBox(height: 20),

                            // Correo
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !authState.isLoading,
                              onChanged: (_) => _clearError(),
                              onFieldSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(_passwordFocus),
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 12),

                            // Contraseña
                            TextFormField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              enabled: !authState.isLoading,
                              onChanged: (_) => _clearError(),
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: authState.isLoading
                                      ? null
                                      : () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: _validatePassword,
                            ),

                            // Olvidé contraseña
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () => context.go('/forgot-password'),
                                style: TextButton.styleFrom(
                                  foregroundColor: cs.primary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 36),
                                ),
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style:
                                      AppTypography.caption(color: cs.primary),
                                ),
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Botón
                            SubmitButton(
                              label: 'Iniciar sesión',
                              isLoading: authState.isLoading,
                              onPressed: _submit,
                            ),

                            // Error
                            if (authState.hasError) ...[
                              const SizedBox(height: 12),
                              ErrorBanner(message: authState.errorMessage!),
                            ],

                            const SizedBox(height: 20),

                            // Enlace a registro
                            AuthLink(
                              question: '¿No tienes cuenta? ',
                              actionLabel: 'Regístrate',
                              enabled: !authState.isLoading,
                              onTap: () => context.go('/register'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

