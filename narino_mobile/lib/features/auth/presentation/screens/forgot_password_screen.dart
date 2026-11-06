import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

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
    FocusScope.of(context).unfocus();
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
    final nc = context.nc;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return AuthScaffold(
      kicker: 'Recupera tu acceso',
      title: _sent ? 'Revisa tu correo' : '¿Olvidaste tu contraseña?',
      subtitle: _sent
          ? null
          : 'No pasa nada. Te enviamos un enlace para crear una nueva.',
      logoAccent: nc.oroA,
      onBack: () => context.go('/login'),
      child: AnimatedSwitcher(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
        child: _sent ? _sentState(nc) : _form(nc),
      ),
    );
  }

  Widget _form(NcColors nc) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthCardTitle(
            'Recuperar contraseña',
            subtitle: 'El enlace es válido durante 30 minutos.',
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            enabled: !_loading,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return 'Ingresa tu correo';
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(t)) {
                return 'Revisa el formato del correo';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            NcBanner.error(context, _error!),
            const SizedBox(height: 14),
          ],
          NcPrimaryButton(
            label: 'Enviar enlace',
            icon: Icons.send_rounded,
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _sentState(NcColors nc) {
    return Column(
      key: const ValueKey('sent'),
      children: [
        NcAccentIcon(
          icon: Icons.mark_email_read_outlined,
          accent: nc.successA,
          size: 76,
          glow: true,
        ),
        const SizedBox(height: 18),
        Text(
          '¡Enlace enviado!',
          textAlign: TextAlign.center,
          style: AppTypography.displaySemiBold(color: nc.textPrimary),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: AppTypography.bodyMedium(color: nc.textSecondary),
            children: [
              const TextSpan(text: 'Lo mandamos a '),
              TextSpan(
                text: _emailCtrl.text.trim(),
                style: TextStyle(
                    color: nc.textPrimary, fontWeight: FontWeight.w600),
              ),
              const TextSpan(
                  text: '. Si no lo ves, revisa spam o promociones.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        NcPrimaryButton(
          label: 'Volver a iniciar sesión',
          icon: Icons.login_rounded,
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => _sent = false),
          child: const Text('Usar otro correo'),
        ),
      ],
    );
  }
}
