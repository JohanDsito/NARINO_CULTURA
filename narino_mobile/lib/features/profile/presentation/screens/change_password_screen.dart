import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../auth/presentation/widgets/auth_fields.dart';
import '../providers/account_security_provider.dart';
import '../widgets/cuenta_ui.dart';

/// Cambia la contraseña con `PATCH users/me/password/` (pide la actual).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _repetirCtrl = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _repetirCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref.read(accountSecurityRepositoryProvider).changePassword(
            current: _actualCtrl.text,
            nueva: _nuevaCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Listo, tu contraseña quedó cambiada')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      var msg = e.toString();
      // El backend responde sin tilde ("contrasena").
      if (msg.toLowerCase().contains('actual no es correcta')) {
        msg = 'La contraseña actual no es correcta.';
      }
      setState(() {
        _enviando = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Scaffold(
      appBar: AppBar(title: const Text('Contraseña')),
      body: Form(
        key: _formKey,
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              CuentaHeader(
                icon: Icons.key_rounded,
                accent: nc.oroA,
                title: 'Cambia tu contraseña',
                message: 'Primero confirma la actual; así sabemos que eres tú.',
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                NcBanner.error(context, _error!),
                const SizedBox(height: 16),
              ],
              PasswordField(
                controller: _actualCtrl,
                label: 'Contraseña actual',
                enabled: !_enviando,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Escribe tu contraseña actual'
                    : null,
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _nuevaCtrl,
                label: 'Contraseña nueva',
                enabled: !_enviando,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final s = v ?? '';
                  if (s.isEmpty) return 'Crea una contraseña nueva';
                  if (!RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(s)) {
                    return 'Cumple los tres requisitos de abajo';
                  }
                  if (s == _actualCtrl.text) {
                    return 'Debe ser distinta a la actual';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              PasswordStrength(password: _nuevaCtrl.text),
              const SizedBox(height: 14),
              PasswordField(
                controller: _repetirCtrl,
                label: 'Repite la contraseña nueva',
                enabled: !_enviando,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _guardar(),
                validator: (v) => v != _nuevaCtrl.text
                    ? 'Las contraseñas no coinciden'
                    : null,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NcGlassBottomBar(
        child: NcPrimaryButton(
          label: 'Guardar contraseña',
          icon: Icons.check_rounded,
          loading: _enviando,
          onPressed: _guardar,
        ),
      ),
    );
  }
}
