import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/nc_button.dart';
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
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: _validateName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Correo'),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _rol,
                  items: [
                    for (final r in _roles)
                      DropdownMenuItem(value: r.value, child: Text(r.label)),
                  ],
                  onChanged: authState.isLoading
                      ? null
                      : (v) => setState(() => _rol = v),
                  decoration: const InputDecoration(labelText: 'Rol'),
                  validator: _validateRole,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    helperText:
                        'Mínimo 8 caracteres, una mayúscula y un número',
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: _validatePassword,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                NcButton(
                  label: 'Registrarme',
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed:
                      authState.isLoading ? null : () => context.go('/login'),
                  child: const Text('Ya tengo cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption {
  const _RoleOption({required this.label, required this.value});

  final String label;
  final String value;
}
