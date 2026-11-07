import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_fields.dart';
import '../providers/account_security_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/cuenta_ui.dart';

/// Eliminación permanente de la cuenta (`DELETE auth/delete-account/`).
/// Acento tomate: es la única acción destructiva de la app.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _acepto = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _eliminar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final nc = context.nc;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar tu cuenta?'),
        content: const Text(
            'Se borrarán tu perfil, tus obras y tu historial. '
            'No hay forma de recuperarlos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: nc.tomateA.ink),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await ref
        .read(deleteAccountProvider.notifier)
        .submit(password: _passwordCtrl.text);
    if (!mounted || ref.read(deleteAccountProvider).hasError) return;

    ref.read(myProfileProvider.notifier).reset();
    ref.read(authProvider.notifier).forceSignOut();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tu cuenta fue eliminada. Gracias por ser parte.')));
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final state = ref.watch(deleteAccountProvider);
    final cargando = state.isLoading;
    final peligro = nc.tomateA;

    return Scaffold(
      appBar: AppBar(title: const Text('Eliminar cuenta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            CuentaHeader(
              icon: Icons.delete_forever_outlined,
              accent: peligro,
              title: 'Antes de irte',
              message: 'Eliminar tu cuenta es definitivo. Esto es lo que pasa:',
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: peligro.tint,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: peligro.fill.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  CuentaPunto(
                      icon: Icons.person_off_outlined,
                      accent: peligro,
                      text: 'Se borran tu perfil, foto y redes.'),
                  CuentaPunto(
                      icon: Icons.palette_outlined,
                      accent: peligro,
                      text: 'Tus obras dejan de verse en el catálogo y la tienda.'),
                  CuentaPunto(
                      icon: Icons.receipt_long_outlined,
                      accent: peligro,
                      text: 'Pierdes el acceso a tus compras, ventas y comprobantes.'),
                  CuentaPunto(
                      icon: Icons.gavel_rounded,
                      accent: peligro,
                      text: 'Si tienes subastas activas, primero deben terminar.'),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (state.hasError) ...[
              NcBanner.error(context, state.error.toString()),
              const SizedBox(height: 16),
            ],
            Text('Confirma que eres tú',
                style: AppTypography.labelSemiBold(color: nc.textPrimary)),
            const SizedBox(height: 10),
            PasswordField(
              controller: _passwordCtrl,
              label: 'Tu contraseña',
              enabled: !cargando,
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Escribe tu contraseña para continuar'
                  : null,
            ),
            const SizedBox(height: 14),
            FormField<bool>(
              initialValue: false,
              validator: (_) =>
                  _acepto ? null : 'Marca la casilla para continuar',
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    value: _acepto,
                    onChanged: cargando
                        ? null
                        : (v) {
                            setState(() => _acepto = v ?? false);
                            field.didChange(v);
                          },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: peligro.fill,
                    checkColor: peligro.onFill,
                    title: Text(
                        'Entiendo que no se puede deshacer',
                        style: AppTypography.bodyMedium(color: nc.textPrimary)),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(field.errorText!,
                          style: AppTypography.bodySmall(color: peligro.ink)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NcGlassBottomBar(
        child: Row(
          children: [
            Expanded(
              child: NcSecondaryButton(
                label: 'Cancelar',
                onPressed: cargando ? null : () => context.pop(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: cargando ? null : _eliminar,
                  style: FilledButton.styleFrom(
                    backgroundColor: peligro.fill,
                    foregroundColor: peligro.onFill,
                    shape: const StadiumBorder(),
                  ),
                  icon: cargando
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: peligro.onFill),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: const Text('Eliminar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
