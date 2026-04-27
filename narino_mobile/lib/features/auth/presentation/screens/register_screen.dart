import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

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

  String? _rol;
  bool _obscurePassword = true;
  late final ProviderSubscription<AuthState> _authSub;

  static const _roles = <_RoleOption>[
    _RoleOption(label: 'Artista', value: 'artista'),
    _RoleOption(label: 'Comprador', value: 'comprador'),
    _RoleOption(label: 'Gestor Cultural', value: 'gestor'),
  ];

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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu nombre';
    return null;
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
    if (v.isEmpty) return 'Ingresa una contraseña';
    final strong = RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!strong.hasMatch(v)) {
      return 'Mínimo 8 caracteres, una mayúscula y un número';
    }
    return null;
  }

  String? _validateRole(String? value) {
    if (value == null || value.isEmpty) return 'Selecciona un rol';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).register(
          nombre: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          rol: _rol!,
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
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      sliver: SliverToBoxAdapter(
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
                                    style: AppTypography.displayBold(
                                      color: AppColors.textPrimaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Únete al ecosistema artístico de Nariño.',
                                    style: AppTypography.quoteItalic(
                                      color: AppColors.textSecondaryDark,
                                    ).copyWith(fontSize: 18),
                                  ),
                                  const SizedBox(height: 16),
                                  _RegisterCard(
                                    nameCtrl: _nameCtrl,
                                    emailCtrl: _emailCtrl,
                                    passwordCtrl: _passwordCtrl,
                                    roles: _roles,
                                    rol: _rol,
                                    isLoading: authState.isLoading,
                                    obscurePassword: _obscurePassword,
                                    onRolChanged: (v) =>
                                        setState(() => _rol = v),
                                    onTogglePassword: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    onSubmit: _submit,
                                    validateName: _validateName,
                                    validateEmail: _validateEmail,
                                    validateRole: _validateRole,
                                    validatePassword: _validatePassword,
                                  ),
                                  const SizedBox(height: 16),
                                  _RegisterFooter(
                                    isLoading: authState.isLoading,
                                    onGoLogin: () => context.go('/login'),
                                  ),
                                ],
                              ),
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

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.roles,
    required this.rol,
    required this.isLoading,
    required this.obscurePassword,
    required this.onRolChanged,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.validateName,
    required this.validateEmail,
    required this.validateRole,
    required this.validatePassword,
  });

  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final List<_RoleOption> roles;
  final String? rol;
  final bool isLoading;
  final bool obscurePassword;
  final ValueChanged<String?> onRolChanged;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;
  final String? Function(String?) validateName;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validateRole;
  final String? Function(String?) validatePassword;

  InputDecoration _decoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hint,
      helperText: helperText,
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
      helperStyle: AppTypography.bodySmall(color: AppColors.textMutedDark),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Datos de tu cuenta',
            style:
                AppTypography.displaySemiBold(color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Completa tus datos para comenzar.',
            style: AppTypography.bodySmall(color: AppColors.textMutedDark)
                .copyWith(fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: nameCtrl,
            textInputAction: TextInputAction.next,
            style: AppTypography.bodyMedium(color: AppColors.textPrimaryDark),
            decoration: _decoration(
              hint: 'Nombre',
              prefixIcon: Icons.person_outline,
            ),
            validator: validateName,
          ),
          const SizedBox(height: 16),
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
          DropdownButtonFormField<String>(
            initialValue: rol,
            items: [
              for (final r in roles)
                DropdownMenuItem(value: r.value, child: Text(r.label)),
            ],
            onChanged: isLoading ? null : onRolChanged,
            dropdownColor: AppColors.bgCardDark,
            style: AppTypography.bodyMedium(color: AppColors.textPrimaryDark),
            iconEnabledColor: AppColors.textMutedDark,
            decoration: _decoration(
              hint: 'Rol',
              prefixIcon: Icons.badge_outlined,
            ),
            validator: validateRole,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordCtrl,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            style: AppTypography.bodyMedium(color: AppColors.textPrimaryDark),
            decoration: _decoration(
              hint: 'Contraseña',
              prefixIcon: Icons.lock_outline_rounded,
              helperText: 'Mínimo 8 caracteres, una mayúscula y un número',
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
          const SizedBox(height: 24),
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
                        valueColor: AlwaysStoppedAnimation(AppColors.oroClaro),
                      ),
                    )
                  : const Text('Registrarme'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterFooter extends StatelessWidget {
  const _RegisterFooter({
    required this.isLoading,
    required this.onGoLogin,
  });

  final bool isLoading;
  final VoidCallback onGoLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿Ya tienes cuenta? ',
              style: AppTypography.bodySmall(color: AppColors.textMutedDark)
                  .copyWith(fontSize: 13),
            ),
            TextButton(
              onPressed: isLoading ? null : onGoLogin,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.tierraDark,
              ),
              child: Text(
                'Iniciar sesión',
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

class _RoleOption {
  const _RoleOption({required this.label, required this.value});

  final String label;
  final String value;
}
