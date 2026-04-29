import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  late final ProviderSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();

    _authSub = ref.listenManual<AuthState>(authProvider, (prev, next) {
      if (!mounted) return;

      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
        return;
      }

      final nextError = next.errorMessage;
      if (nextError != null &&
          nextError.isNotEmpty &&
          nextError != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(nextError)));
      }
    });
  }

  @override
  void dispose() {
    _authSub.close();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo';
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(v)) return 'Correo inválido';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña';
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

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.obsidiana,
        elevation: 0,
        title: Text(
          'Nariño Cultura',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroHeight =
                (constraints.maxHeight * 0.40).clamp(260.0, 360.0);

            return Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.obsidiana, AppColors.bgDark],
                      ),
                    ),
                  ),
                ),
                CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _HeroMotivational(height: heroHeight),
                                const SizedBox(height: 16),
                                _FormCard(
                                  formKey: _formKey,
                                  emailCtrl: _emailCtrl,
                                  passwordCtrl: _passwordCtrl,
                                  obscurePassword: _obscurePassword,
                                  isLoading: authState.isLoading,
                                  onTogglePassword: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  onSubmit: _submit,
                                  validateEmail: _validateEmail,
                                  validatePassword: _validatePassword,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: _Footer(
                              isLoading: authState.isLoading,
                              onGoRegister: () => context.go('/register'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroMotivational extends StatelessWidget {
  const _HeroMotivational({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isCompact = height < 300;
    final titleSize = isCompact ? 26.0 : 28.0;
    final subtitleSize = isCompact ? 18.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'El arte de Nariño, en tus manos.',
          style: AppTypography.displayBold(color: AppColors.textPrimaryDark)
              .copyWith(fontSize: titleSize),
        ),
        const SizedBox(height: 8),
        Text(
          'Descubre, colecciona y conecta con los artistas de nuestra región.',
          style: AppTypography.quoteItalic(color: AppColors.textSecondaryDark)
              .copyWith(fontSize: subtitleSize),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.validateEmail,
    required this.validatePassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;

  InputDecoration _decoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: AppColors.textMutedDark),
      suffixIcon: suffixIcon,
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.tierraDark, width: 1.5),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
      hintStyle: AppTypography.bodyMedium(color: AppColors.textMutedDark),
      errorStyle: AppTypography.bodySmall(color: AppColors.error)
          .copyWith(fontSize: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Iniciar sesión',
              style: AppTypography.displaySemiBold(
                  color: AppColors.textPrimaryDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Accede a tu cuenta artística',
              style: AppTypography.bodySmall(color: AppColors.textMutedDark)
                  .copyWith(fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              style: AppTypography.bodyMedium(color: AppColors.textPrimaryDark),
              decoration: _decoration(
                hint: 'Correo electrónico',
                prefixIcon: Icons.alternate_email,
              ),
              validator: validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordCtrl,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              style: AppTypography.bodyMedium(color: AppColors.textPrimaryDark),
              decoration: _decoration(
                hint: 'Contraseña',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  onPressed: isLoading ? null : onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textMutedDark,
                  ),
                ),
              ),
              validator: validatePassword,
              onFieldSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap:
                    isLoading ? null : () => context.push('/forgot-password'),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: AppTypography.caption(color: AppColors.tierraProfunda),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSubmit,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return AppColors.tierraDark.withValues(alpha: 0.60);
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return AppColors.tierraDark.withValues(alpha: 0.85);
                    }
                    return AppColors.tierraDark;
                  }),
                  foregroundColor: const WidgetStatePropertyAll(Colors.white),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  overlayColor: WidgetStatePropertyAll(
                    Colors.white.withValues(alpha: 0.10),
                  ),
                  textStyle: WidgetStatePropertyAll(AppTypography.buttonText()),
                  elevation: const WidgetStatePropertyAll(0),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.oroClaro),
                        ),
                      )
                    : const Text('Entrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.isLoading,
    required this.onGoRegister,
  });

  final bool isLoading;
  final VoidCallback onGoRegister;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿No tienes cuenta? ',
              style: AppTypography.bodySmall(color: AppColors.textMutedDark)
                  .copyWith(fontSize: 13),
            ),
            TextButton(
              onPressed: isLoading ? null : onGoRegister,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.tierraDark,
              ),
              child: Text(
                'Crear cuenta',
                style: AppTypography.labelSemiBold(color: AppColors.tierraDark)
                    .copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Nariño Cultura · Plataforma para el ecosistema artístico',
          textAlign: TextAlign.center,
          style: AppTypography.caption(color: AppColors.textMutedDark),
        ),
      ],
    );
  }
}
