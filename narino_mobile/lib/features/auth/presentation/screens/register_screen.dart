import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

// ─── Modelo de rol ────────────────────────────────────────────────────────────

class _RoleOption {
  const _RoleOption({
    required this.label,
    required this.value,
    required this.icon,
    required this.description,
  });

  final String label;
  final String value;
  final IconData icon;
  final String description;
}

const _kRoles = <_RoleOption>[
  _RoleOption(
    label: 'Artista',
    value: 'artista',
    icon: Icons.palette_outlined,
    description: 'Publica y vende tu obra',
  ),
  _RoleOption(
    label: 'Comprador',
    value: 'comprador',
    icon: Icons.shopping_bag_outlined,
    description: 'Descubre y adquiere arte',
  ),
  _RoleOption(
    label: 'Gestor Cultural',
    value: 'gestor',
    icon: Icons.account_balance_outlined,
    description: 'Gestiona eventos y espacios',
  ),
];

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

  String? _rol;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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

    if (_rol == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Selecciona un rol para continuar')),
        );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).register(
          firstName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _rol!,
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
            const _RegisterHero(),

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
                                suffixIcon: _ToggleVisibility(
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
                                suffixIcon: _ToggleVisibility(
                                  obscure: _obscureConfirm,
                                  disabled: isLoading,
                                  onToggle: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: _validateConfirm,
                            ),
                            const SizedBox(height: 20),

                            // Selector de rol
                            _RolSelector(
                              selected: _rol,
                              disabled: isLoading,
                              onSelect: (v) => setState(() => _rol = v),
                            ),
                            const SizedBox(height: 20),

                            // Botón
                            _SubmitButton(
                              label: 'Crear cuenta',
                              isLoading: isLoading,
                              onPressed: _submit,
                            ),

                            // Error
                            if (authState.hasError) ...[
                              const SizedBox(height: 12),
                              _ErrorBanner(message: authState.errorMessage!),
                            ],

                            const SizedBox(height: 20),

                            // Enlace a login
                            _AuthLink(
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

// ─── Hero del registro ────────────────────────────────────────────────────────

class _RegisterHero extends StatelessWidget {
  const _RegisterHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.obsidiana,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.oroAndino,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.landscape_outlined,
                  size: 26, color: AppColors.obsidiana),
            ),
            const SizedBox(width: 12),
            Text(
              'Nariño Cultura',
              style: AppTypography.displayBold(color: AppColors.oroClaro)
                  .copyWith(fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Selector de rol con tarjetas ─────────────────────────────────────────────

class _RolSelector extends StatelessWidget {
  const _RolSelector({
    required this.selected,
    required this.disabled,
    required this.onSelect,
  });

  final String? selected;
  final bool disabled;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.badge_outlined, size: 16, color: textMuted),
            const SizedBox(width: 6),
            Text(
              'Rol',
              style: AppTypography.labelSemiBold(color: textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(_kRoles.length, (i) {
          final role = _kRoles[i];
          final isSelected = selected == role.value;
          return Padding(
            padding: EdgeInsets.only(bottom: i < _kRoles.length - 1 ? 8 : 0),
            child: _RolCard(
              role: role,
              isSelected: isSelected,
              disabled: disabled,
              onTap: () => onSelect(role.value),
            ),
          );
        }),
      ],
    );
  }
}

class _RolCard extends StatelessWidget {
  const _RolCard({
    required this.role,
    required this.isSelected,
    required this.disabled,
    required this.onTap,
  });

  final _RoleOption role;
  final bool isSelected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final selectedBg = isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              role.icon,
              size: 22,
              color: isSelected ? cs.primary : textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: AppTypography.labelSemiBold(
                      color: isSelected ? cs.primary : textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.description,
                    style: AppTypography.caption(color: textMuted),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(Icons.check_circle, color: cs.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets compartidos ──────────────────────────────────────────────────────

class _ToggleVisibility extends StatelessWidget {
  const _ToggleVisibility({
    required this.obscure,
    required this.disabled,
    required this.onToggle,
  });

  final bool obscure;
  final bool disabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: disabled ? null : onToggle,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );
  }
}

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
