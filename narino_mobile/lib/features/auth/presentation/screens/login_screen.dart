import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

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
      if (next.status == AuthStatus.authenticated) context.go('/home');
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
              child: _LoginHero(),
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
                            _SubmitButton(
                              label: 'Iniciar sesión',
                              isLoading: authState.isLoading,
                              onPressed: _submit,
                            ),

                            // Error
                            if (authState.hasError) ...[
                              const SizedBox(height: 12),
                              _ErrorBanner(message: authState.errorMessage!),
                            ],

                            const SizedBox(height: 20),

                            // Enlace a registro
                            _AuthLink(
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

// ─── Hero del login ───────────────────────────────────────────────────────────

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.obsidiana,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.oroAndino,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.landscape_outlined,
                size: 40,
                color: AppColors.obsidiana,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Nariño Cultura',
              style: AppTypography.displayBold(color: AppColors.oroClaro),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Arte que nace desde Nariño',
              style: AppTypography.quoteItalic(
                color: AppColors.oroClaro.withValues(alpha: 0.70),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets compartidos de auth ──────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall(color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthLink extends StatelessWidget {
  const _AuthLink({
    required this.question,
    required this.actionLabel,
    required this.enabled,
    required this.onTap,
  });

  final String question;
  final String actionLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          question,
          style: AppTypography.bodySmall(color: textMuted),
        ),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Text(
            actionLabel,
            style: AppTypography.bodySmall(color: cs.primary)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
