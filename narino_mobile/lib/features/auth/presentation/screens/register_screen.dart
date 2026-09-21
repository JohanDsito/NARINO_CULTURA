import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';
import 'register_screen/auth_link.dart';
import 'register_screen/error_banner.dart';
import 'register_screen/register_hero.dart';
import 'register_screen/submit_button.dart';
import 'register_screen/terms_checkbox.dart';
import 'register_screen/toggle_visibility.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late final ProviderSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = ref.listenManual<AuthState>(authProvider, (prev, next) {
      if (!mounted) return;
      if (next.status == AuthStatus.registrationPending) {
        context.go(
          '/verify-email-pending',
          extra: _emailCtrl.text.trim(),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub.close();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _clearError() => ref.read(authProvider.notifier).clearError();

  // ─── Validadores ──────────────────────────────────────────────────────────

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu nombre';
    if (v.length < 3) return 'Mínimo 3 caracteres';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
      return 'Correo inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa una contraseña';
    if (!RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(v)) {
      return 'Mínimo 8 caracteres, una mayúscula y un número';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != _passwordCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
                'Debes aceptar los Términos y Condiciones para registrarte'),
          ),
        );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).register(
          firstName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: 'ARTISTA',
        );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero ──────────────────────────────────────────────────────
            const RegisterHero(),

            // ── Formulario ────────────────────────────────────────────────
            Expanded(
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
                              'Crear cuenta',
                              style: AppTypography.displaySemiBold(
                                  color: textPrimary),
                            ),
                            const SizedBox(height: 20),

                            // Nombre
                            TextFormField(
                              controller: _nameCtrl,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              onChanged: (_) => _clearError(),
                              onFieldSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(_emailFocus),
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: _validateName,
                            ),
                            const SizedBox(height: 12),

                            // Correo
                            TextFormField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
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
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              onChanged: (_) => _clearError(),
                              onFieldSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(_confirmFocus),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: ToggleVisibility(
                                  obscure: _obscurePassword,
                                  disabled: isLoading,
                                  onToggle: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 12),

                            // Confirmar contraseña
                            TextFormField(
                              controller: _confirmCtrl,
                              focusNode: _confirmFocus,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              enabled: !isLoading,
                              onChanged: (_) => _clearError(),
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Confirmar contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: ToggleVisibility(
                                  obscure: _obscureConfirm,
                                  disabled: isLoading,
                                  onToggle: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: _validateConfirm,
                            ),
                            const SizedBox(height: 20),

                            // Términos y condiciones
                            TermsCheckbox(
                              accepted: _acceptedTerms,
                              disabled: isLoading,
                              onChanged: (v) =>
                                  setState(() => _acceptedTerms = v),
                            ),
                            const SizedBox(height: 16),

                            // Botón
                            SubmitButton(
                              label: 'Crear cuenta',
                              isLoading: isLoading,
                              onPressed: _submit,
                            ),

                            // Error
                            if (authState.hasError) ...[
                              const SizedBox(height: 12),
                              ErrorBanner(message: authState.errorMessage!),
                            ],

                            const SizedBox(height: 20),

                            // Enlace a login
                            AuthLink(
                              question: '¿Ya tienes cuenta? ',
                              actionLabel: 'Inicia sesión',
                              enabled: !isLoading,
                              onTap: () => context.go('/login'),
                            ),
                            const SizedBox(height: 8),
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
