import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _sent = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Hero ──────────────────────────────────────────────────────────
          const _AuthHero(compact: true),

          // ── Contenido ─────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _sent
                    ? _SuccessState(
                        key: const ValueKey('success'),
                        email: _emailCtrl.text.trim(),
                      )
                    : _ForgotForm(
                        key: const ValueKey('form'),
                        formKey: _formKey,
                        emailCtrl: _emailCtrl,
                        loading: _loading,
                        error: _error,
                        onSubmit: _submit,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formulario ───────────────────────────────────────────────────────────────

class _ForgotForm extends StatelessWidget {
  const _ForgotForm({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recuperar contraseña',
            style: AppTypography.displaySemiBold(color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña. El enlace es válido por 30 minutos.',
            style: AppTypography.bodySmall(color: textMuted),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !loading,
            style: AppTypography.bodyMedium(color: textPrimary),
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                return 'Correo no válido';
              }
              return null;
            },
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 20),
          if (error != null) ...[
            _ErrorBanner(message: error!),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              child: loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: cs.onPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Enviar enlace',
                      style: AppTypography.buttonText(color: cs.onPrimary),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Volver al login'),
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Estado de éxito ──────────────────────────────────────────────────────────

class _SuccessState extends StatelessWidget {
  const _SuccessState({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: cs.tertiary.withAlpha(18),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            color: cs.tertiary,
            size: 42,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '¡Correo enviado!',
          style: AppTypography.displaySemiBold(color: textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Revisa tu bandeja en $email.\nEl enlace expira en 30 minutos.',
          style: AppTypography.bodyMedium(color: textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '¿No lo ves? Revisa la carpeta de spam.',
          style: AppTypography.bodySmall(color: textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login_outlined),
            label: Text(
              'Volver al login',
              style: AppTypography.buttonText(color: cs.onPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Widgets compartidos ──────────────────────────────────────────────────────

/// Hero reutilizable para las pantallas de auth.
/// [compact] reduce el tamaño cuando hay menos espacio vertical.
class _AuthHero extends StatelessWidget {
  const _AuthHero({this.compact = false, this.subtitle});

  final bool compact;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.obsidiana,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 44 : 72,
                height: compact ? 44 : 72,
                decoration: BoxDecoration(
                  color: AppColors.oroAndino,
                  borderRadius: BorderRadius.circular(compact ? 10 : 18),
                ),
                child: Icon(
                  Icons.landscape_outlined,
                  color: AppColors.obsidiana,
                  size: compact ? 22 : 40,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nariño Cultura',
                style: compact
                    ? AppTypography.labelSemiBold(color: AppColors.oroClaro)
                    : AppTypography.displayBold(color: AppColors.oroClaro),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null && !compact) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: AppTypography.quoteItalic(
                    color: AppColors.oroClaro.withAlpha(70),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withAlpha(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
