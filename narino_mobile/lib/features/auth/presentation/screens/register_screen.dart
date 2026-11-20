import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_scaffold.dart';

/// Roles que el backend permite en el auto-registro.
enum _Rol { artista, comprador }

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

  _Rol? _rol;
  bool _acceptedTerms = false;
  bool _intentado = false;
  late final ProviderSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() => setState(() {}));
    _authSub = ref.listenManual<AuthState>(authProvider, (prev, next) {
      if (!mounted) return;
      if (next.status == AuthStatus.registrationPending) {
        context.go('/verify-email-pending', extra: _emailCtrl.text.trim());
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
      return 'Revisa el formato del correo';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Crea una contraseña';
    if (!RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(v)) {
      return 'Cumple los tres requisitos de abajo';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Repite tu contraseña';
    if (value != _passwordCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  // ─── Envío ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _intentado = true);
    final formOk = _formKey.currentState!.validate();
    if (!formOk || _rol == null || !_acceptedTerms) return;
    await ref.read(authProvider.notifier).register(
          firstName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _rol == _Rol.artista ? 'ARTISTA' : 'COMPRADOR',
        );
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final auth = ref.watch(authProvider);
    final loading = auth.isLoading;

    Widget label(String text) => Text(
          text,
          style: AppTypography.labelSemiBold(color: nc.textPrimary)
              .copyWith(fontSize: 14),
        );

    return AuthScaffold(
      kicker: 'Únete a la fiesta',
      title: 'Crea tu cuenta',
      subtitle: 'Toma menos de un minuto. Luego te enviaremos un correo para '
          'verificarla.',
      logoAccent: nc.naranjaA,
      onBack: () => context.go('/login'),
      footer: AuthLink(
        question: '¿Ya tienes cuenta?',
        actionLabel: 'Inicia sesión',
        enabled: !loading,
        onTap: () => context.go('/login'),
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Rol ──
              label('¿Cómo quieres participar?'),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: RoleOption(
                        emoji: '🎨',
                        title: 'Crear y vender',
                        description: 'Publica tus obras, subástalas y crea '
                            'eventos.',
                        accent: nc.catalogo,
                        selected: _rol == _Rol.artista,
                        onTap: loading
                            ? null
                            : () => setState(() => _rol = _Rol.artista),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RoleOption(
                        emoji: '🛍️',
                        title: 'Descubrir y comprar',
                        description: 'Compra, puja y asiste a la agenda '
                            'cultural.',
                        accent: nc.tienda,
                        selected: _rol == _Rol.comprador,
                        onTap: loading
                            ? null
                            : () => setState(() => _rol = _Rol.comprador),
                      ),
                    ),
                  ],
                ),
              ),
              if (_intentado && _rol == null) ...[
                const SizedBox(height: 8),
                Text('Elige una opción para continuar',
                    style: AppTypography.bodySmall(color: nc.tomateA.ink)),
              ],
              const SizedBox(height: 24),

              // ── Datos ──
              label('Tus datos'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                enabled: !loading,
                onChanged: (_) => _clearError(),
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                enabled: !loading,
                onChanged: (_) => _clearError(),
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _passwordCtrl,
                focusNode: _passwordFocus,
                label: 'Contraseña',
                enabled: !loading,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => _clearError(),
                onSubmitted: (_) => _confirmFocus.requestFocus(),
                validator: _validatePassword,
              ),
              const SizedBox(height: 10),
              PasswordStrength(password: _passwordCtrl.text),
              const SizedBox(height: 14),
              PasswordField(
                controller: _confirmCtrl,
                focusNode: _confirmFocus,
                label: 'Confirmar contraseña',
                enabled: !loading,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => _clearError(),
                onSubmitted: (_) => _submit(),
                validator: _validateConfirm,
              ),
              const SizedBox(height: 20),

              // ── Términos ──
              TermsCheck(
                accepted: _acceptedTerms,
                enabled: !loading,
                showError: _intentado && !_acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v),
              ),
              if (_intentado && !_acceptedTerms) ...[
                const SizedBox(height: 8),
                Text('Debes aceptar los términos para registrarte',
                    style: AppTypography.bodySmall(color: nc.tomateA.ink)),
              ],
              const SizedBox(height: 20),
              if (auth.hasError) ...[
                NcBanner.error(context, auth.errorMessage!),
                const SizedBox(height: 14),
              ],
              NcPrimaryButton(
                label: 'Crear cuenta',
                loading: loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
